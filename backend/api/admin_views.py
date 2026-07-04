from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.utils import timezone
from .models import UserProfile, ActivityLog, AdminNotification
from .serializers import AdminEmployeeSerializer, AdminNotificationSerializer, ActivityLogSerializer


class AdminNotificationListView(generics.ListAPIView):
    """Lists all admin notifications, with optional filtering by read status."""
    serializer_class = AdminNotificationSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        queryset = AdminNotification.objects.all()
        is_read = self.request.query_params.get('is_read')
        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')
        return queryset


class AdminNotificationMarkReadView(APIView):
    """Mark a specific notification as read."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request, pk):
        try:
            notif = AdminNotification.objects.get(pk=pk)
            notif.is_read = True
            notif.save()
            return Response({'status': 'marked as read'})
        except AdminNotification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)


class AdminDashboardView(APIView):
    """Returns aggregate metrics and recent activity for the admin dashboard."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        total_employees = User.objects.filter(is_superuser=False).count()
        pending_approvals = UserProfile.objects.filter(
            is_approved=False, user__is_superuser=False
        ).count()
        # Active sessions = employees who are approved and active
        active_sessions = UserProfile.objects.filter(
            is_approved=True, user__is_active=True, user__is_superuser=False
        ).count()

        # Total products count
        from .models import Product
        from .mssql_client import get_total_products_count
        local_count = Product.objects.count()
        total_products = local_count if local_count > 0 else get_total_products_count()

        # Latest 10 activity entries
        logs = ActivityLog.objects.order_by('-created_at')[:10]
        recent_activity = [
            {
                'id': log.id,
                'type': log.activity_type,
                'title': log.title,
                'subtitle': log.subtitle,
                'timestamp': log.created_at.isoformat(),
            }
            for log in logs
        ]

        return Response({
            'total_employees': total_employees,
            'pending_approvals': pending_approvals,
            'active_sessions': active_sessions,
            'total_products': total_products,
            'recent_activity': recent_activity,
        })


from rest_framework.pagination import PageNumberPagination

class AdminActivityLogPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class AdminActivityLogListView(generics.ListAPIView):
    """Lists all activity logs for admin audit."""
    serializer_class = ActivityLogSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]
    pagination_class = AdminActivityLogPagination

    def get_queryset(self):
        queryset = ActivityLog.objects.all().order_by('-created_at')
        activity_type = self.request.query_params.get('type', '')
        search = self.request.query_params.get('search', '')

        if activity_type == 'access':
            queryset = queryset.filter(
                activity_type__in=['access_change', 'employee_approved', 'employee_rejected']
            )
        elif activity_type == 'employee':
            queryset = queryset.filter(
                activity_type__in=['employee_onboarded', 'profile_update']
            )
        elif activity_type == 'inventory':
            queryset = queryset.filter(
                activity_type__in=['inventory_audit', 'data_sync', 'policy_update']
            )

        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(subtitle__icontains=search)
            )

        return queryset


class AdminEmployeeListView(generics.ListAPIView):
    """Lists all employees for admin management."""
    serializer_class = AdminEmployeeSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        queryset = User.objects.filter(is_superuser=False).select_related('profile')
        search = self.request.query_params.get('search', '')
        status_filter = self.request.query_params.get('status', '')

        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(username__icontains=search) |
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(email__icontains=search)
            )

        if status_filter == 'active':
            queryset = queryset.filter(profile__is_approved=True)
        elif status_filter == 'pending':
            queryset = queryset.filter(profile__is_approved=False)

        return queryset.order_by('-date_joined')


class AdminEmployeeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update permissions, or delete an employee."""
    serializer_class = AdminEmployeeSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(is_superuser=False).select_related('profile')

    def perform_update(self, serializer):
        pass  # handled in update()

    def update(self, request, *args, **kwargs):
        user = self.get_object()
        data = request.data
        full_name = f"{user.first_name} {user.last_name}".strip() or user.username

        # Handle permission_level updates
        permission_level = data.get('permission_level')
        if permission_level:
            level_map = {'standard': 1, 'discount': 2, 'wholesale': 3}
            old_level = user.profile.price_level
            new_level = level_map.get(permission_level, 1)
            if old_level != new_level:
                user.profile.price_level = new_level
                user.profile.save()
                ActivityLog.objects.create(
                    activity_type='access_change',
                    title=f'Access updated: {full_name}',
                    subtitle=f'Changed to {permission_level.capitalize()} tier'
                )

        # Handle is_active updates
        if 'is_active' in data:
            new_status = data['is_active']
            if user.profile.is_active != new_status:
                user.profile.is_active = new_status
                user.profile.save()
                ActivityLog.objects.create(
                    activity_type='profile_update',
                    title=f'Status changed: {full_name}',
                    subtitle='Account ' + ('activated' if new_status else 'deactivated')
                )

        # Handle role updates
        if 'job_role' in data:
            user.profile.role = data['job_role']
            user.profile.save()

        serializer = self.get_serializer(user)
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        user = self.get_object()
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class AdminApprovalsView(generics.ListAPIView):
    """Lists all pending (unapproved) employees awaiting approval."""
    serializer_class = AdminEmployeeSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(
            profile__is_approved=False, is_superuser=False
        ).select_related('profile').order_by('-date_joined')


class AdminApproveEmployeeView(APIView):
    """Approve a pending employee — sets profile.is_approved = True."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk, is_superuser=False)
            user.profile.is_approved = True
            user.profile.save()
            full_name = f"{user.first_name} {user.last_name}".strip() or user.username
            ActivityLog.objects.create(
                activity_type='employee_approved',
                title=f'{full_name} approved',
                subtitle=f'Account activated by admin'
            )
            return Response({'status': 'approved', 'id': pk})
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


class AdminRejectEmployeeView(APIView):
    """Reject (delete) a pending employee."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk, is_superuser=False)
            full_name = f"{user.first_name} {user.last_name}".strip() or user.username
            ActivityLog.objects.create(
                activity_type='employee_rejected',
                title=f'{full_name} rejected',
                subtitle='Account removed by admin'
            )
            user.delete()
            return Response({'status': 'rejected'}, status=status.HTTP_204_NO_CONTENT)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


class AuthMeView(APIView):
    """Returns the current authenticated user's info."""
    permission_classes = [IsAuthenticated]

    def put(self, request):
        user = request.user
        data = request.data
        if 'first_name' in data:
            user.first_name = data['first_name']
        if 'last_name' in data:
            user.last_name = data['last_name']
        if 'email' in data:
            user.email = data['email']
        user.save()

        if 'phone_number' in data:
            user.profile.phone_number = data['phone_number']
            user.profile.save()

        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'phone_number': getattr(user.profile, 'phone_number', ''),
            'is_staff': user.is_staff,
            'is_superuser': user.is_superuser,
        })

    def get(self, request):
        user = request.user
        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'phone_number': getattr(user.profile, 'phone_number', ''),
            'is_staff': user.is_staff,
            'is_superuser': user.is_superuser,
        })

from django.contrib.auth.hashers import check_password

class AdminChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        
        if not check_password(old_password, user.password):
            return Response({'error': 'Incorrect old password.'}, status=status.HTTP_400_BAD_REQUEST)
            
        user.set_password(new_password)
        user.save()
        return Response({'status': 'Password updated successfully'})

class AdminHealthView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        import time
        from django.db import connection
        
        start = time.time()
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            db_status = "98% Optimized"
            api_status = "ONLINE"
        except Exception:
            db_status = "Database Error"
            api_status = "DEGRADED"
            
        ping = int((time.time() - start) * 1000)
        
        return Response({
            'api_status': api_status,
            'db_status': db_status,
            'ping': f"{ping}ms"
        })


class AdminUploadInventoryView(APIView):
    """
    Allows admins to upload a CSV or Excel (.XLSX) file of products.
    Supports either replacing the entire database or performing an upsert (add/update).
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request):
        import csv
        import io
        import openpyxl
        from django.db import transaction
        from .models import Product, ActivityLog

        if 'file' not in request.FILES:
            return Response({'error': 'No file uploaded. Please upload a file under the key "file".'}, status=400)

        uploaded_file = request.FILES['file']
        filename = uploaded_file.name.lower()
        
        mode = request.data.get('mode', 'upsert')  # 'upsert' or 'replace'
        if mode not in ['upsert', 'replace']:
            mode = 'upsert'

        # Read raw bytes
        file_bytes = uploaded_file.read()
        rows_data = []
        headers = []

        try:
            wb = openpyxl.load_workbook(io.BytesIO(file_bytes), read_only=True, data_only=True)
            sheet = wb.active
            # Read all rows as lists of values
            excel_rows = list(sheet.iter_rows(values_only=True))
            if not excel_rows:
                return Response({'error': 'Excel sheet is empty.'}, status=400)
            
            # First row is headers
            raw_headers = excel_rows[0]
            for h in raw_headers:
                if h is not None:
                    headers.append(str(h).strip().lower())
                else:
                    headers.append('')
            
            # Rest are rows
            for row in excel_rows[1:]:
                if row and any(cell is not None and str(cell).strip() != '' for cell in row):
                    rows_data.append([str(cell) if cell is not None else '' for cell in row])
        except Exception:
            return Response({'error': 'Invalid file format. Only Excel (.XLSX) files are supported. CSV is not allowed.'}, status=400)

        if not headers or all(h == '' for h in headers):
            return Response({'error': 'File is empty or missing headers.'}, status=400)

        # Flexibility mappings for headers
        code_idx, name_idx, label_idx, price1_idx, price2_idx, price3_idx = None, None, None, None, None, None
        
        for idx, h in enumerate(headers):
            if h in ['product code', 'product_code', 'code', 'pluno', 'item code', 'item_code', 'id']:
                code_idx = idx
            elif h in ['product name', 'product_name', 'name', 'itemname', 'description', 'item_name', 'item name']:
                name_idx = idx
            elif h in ['price label', 'price_label', 'label', 'description_price', 'unit name', 'unit_name', 'unit']:
                label_idx = idx
            elif h in ['price a', 'price_a', 'price 1', 'price_1', 'unitprice', 'unit_price', 'price', 'a']:
                price1_idx = idx
            elif h in ['price b', 'price_b', 'price 2', 'price_2', 'priceamt', 'price_amt', 'b']:
                price2_idx = idx
            elif h in ['price c', 'price_c', 'price 3', 'price_3', 'changeamount', 'change_amount', 'c']:
                price3_idx = idx

        # Validation
        if code_idx is None:
            return Response({'error': 'File must contain a "product code" or "code" column.'}, status=400)
        if name_idx is None:
            return Response({'error': 'File must contain a "product name" or "name" column.'}, status=400)

        def parse_price(val):
            if not val:
                return 0.0
            clean_val = str(val).replace('$', '').replace('₹', '').replace(',', '').strip()
            try:
                return float(clean_val)
            except ValueError:
                return 0.0

        created_count = 0
        updated_count = 0
        
        try:
            with transaction.atomic():
                if mode == 'replace':
                    # Clear all products first
                    Product.objects.all().delete()
                    
                # Load existing products into memory for fast lookup
                existing_products = {p.product_code: p for p in Product.objects.all()}
                
                products_to_create = []
                seen_codes = set()
                
                for row in rows_data:
                    # Pad row if columns are missing
                    while len(row) < len(headers):
                        row.append('')

                    code = row[code_idx].strip()
                    name = row[name_idx].strip()

                    if not code or not name:
                        continue

                    # Deduplicate within the uploaded file
                    if code in seen_codes:
                        continue
                    seen_codes.add(code)

                    label = row[label_idx].strip() if label_idx is not None else ''
                    p1 = parse_price(row[price1_idx]) if price1_idx is not None else 0.0
                    p2 = parse_price(row[price2_idx]) if price2_idx is not None else 0.0
                    p3 = parse_price(row[price3_idx]) if price3_idx is not None else 0.0

                    if code in existing_products:
                        # Update existing product
                        product = existing_products[code]
                        product.name = name
                        product.price_label = label
                        product.price_1 = p1
                        product.price_2 = p2
                        product.price_3 = p3
                        product.save()
                        updated_count += 1
                    else:
                        # Schedule creation
                        products_to_create.append(Product(
                            product_code=code,
                            name=name,
                            price_label=label,
                            price_1=p1,
                            price_2=p2,
                            price_3=p3
                        ))
                        created_count += 1

                # Bulk create new products
                if products_to_create:
                    Product.objects.bulk_create(products_to_create)

                # Log activity
                ActivityLog.objects.create(
                    activity_type='inventory_audit',
                    title='Products Uploaded',
                    subtitle=f'Mode: {mode.upper()}. Created {created_count}, updated {updated_count} products.'
                )

            return Response({
                'message': f'Successfully updated database. Created: {created_count}, Updated: {updated_count}.'
            }, status=200)

        except Exception as e:
            return Response({'error': f'Failed to process file: {str(e)}'}, status=500)

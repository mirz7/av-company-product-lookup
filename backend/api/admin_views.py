from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Product, UserProfile, ActivityLog, AdminNotification
from .serializers import AdminEmployeeSerializer, AdminNotificationSerializer


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
        total_products = Product.objects.count()
        # Active sessions = employees who are approved and active
        active_sessions = UserProfile.objects.filter(
            is_approved=True, user__is_active=True, user__is_superuser=False
        ).count()

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
            'total_products': total_products,
            'active_sessions': active_sessions,
            'recent_activity': recent_activity,
        })


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
            if user.is_active != new_status:
                user.is_active = new_status
                user.save()
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

    def get(self, request):
        user = request.user
        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'is_staff': user.is_staff,
            'is_superuser': user.is_superuser,
        })

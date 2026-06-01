from rest_framework import generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Product
from .serializers import ProductSerializer, UserRegistrationSerializer, UserProfileSerializer
from rest_framework.exceptions import NotFound

# ── SQL Server product search ─────────────────────────────────────────────────
# The billing database lives on SQL Server and is accessed exclusively via
# raw pyodbc queries.  Django's ORM is NOT used for these tables so that we
# never risk altering the client's existing billing schema.
from .mssql_connection import get_mssql_connection


class ProductSearchView(APIView):
    """
    GET /api/products/?query=<barcode_or_product_code>

    Searches the SQL Server billing database using both the product code (PluNo)
    and the barcode (BarCode) so staff can scan or type either value.

    Response fields (identical to the previous ORM-based response so the
    Flutter app requires no changes):
        product_code  – PluNo from ItemMaster
        name          – ItemName from ItemMaster
        price         – PriceAmt (user's assigned price level from UserProfile)
        price_1       – PriceAmt  (standard price)
        price_2       – CasePrice (discount price)
        price_3       – UnitPrice (wholesale price)
        barcode       – BarCode from ItemMasterFinFl (may be null)
    """
    permission_classes = [IsAuthenticated]

    # Raw SQL that joins the three billing tables.
    # Parametrised with ? placeholders (pyodbc style) to prevent SQL injection.
    _SEARCH_SQL = """
        SELECT
            IM.ItemName,
            IMF.BarCode,
            IMP.PriceAmt,
            IMP.CasePrice,
            IMP.UnitPrice,
            IM.PluNo
        FROM ItemMaster IM
        LEFT JOIN ItemMasterFinFl IMF
            ON IM.ItmId = IMF.ItmId
        LEFT JOIN ItemMasterPriceFL IMP
            ON IM.ItmId = IMP.ItmId
        WHERE
            IM.PluNo    = ?
            OR IMF.BarCode = ?
    """

    # SQL for returning a sample of products when no query is provided
    # (mirrors the old behaviour of returning the first 30 products).
    _BROWSE_SQL = """
        SELECT TOP 30
            IM.ItemName,
            IMF.BarCode,
            IMP.PriceAmt,
            IMP.CasePrice,
            IMP.UnitPrice,
            IM.PluNo
        FROM ItemMaster IM
        LEFT JOIN ItemMasterFinFl IMF
            ON IM.ItmId = IMF.ItmId
        LEFT JOIN ItemMasterPriceFL IMP
            ON IM.ItmId = IMP.ItmId
    """

    def _get_price_level(self, request):
        """Return the price level (1/2/3) for the authenticated user."""
        try:
            return request.user.profile.price_level
        except Exception:
            return 1  # default to standard pricing

    def _row_to_dict(self, row, price_level):
        """
        Convert a pyodbc Row to the dict shape expected by the Flutter app.

        price  – resolved to the field that matches the user's price level:
                   level 1 → PriceAmt   (standard)
                   level 2 → CasePrice  (discount)
                   level 3 → UnitPrice  (wholesale)
        """
        item_name  = row[0] or ''
        barcode    = row[1] or ''
        price_amt  = float(row[2] or 0)
        case_price = float(row[3] or 0)
        unit_price = float(row[4] or 0)
        plu_no     = str(row[5] or '')

        # Resolve the "active" price based on the user's permission level
        if price_level == 2:
            active_price = case_price
        elif price_level == 3:
            active_price = unit_price
        else:
            active_price = price_amt

        return {
            'product_code': plu_no,
            'name':         item_name,
            'barcode':      barcode,
            'price':        active_price,
            'price_1':      price_amt,
            'price_2':      case_price,
            'price_3':      unit_price,
        }

    def get(self, request):
        # Accept both ?query= (new) and ?code= (legacy frontend compatibility)
        query = (request.query_params.get('query') or request.query_params.get('code', '')).strip()
        price_level = self._get_price_level(request)

        # Check if mock mode is requested or configured in settings/env
        import os
        is_mock_mode = os.environ.get('MOCK_DATABASE', 'False').lower() == 'true'

        if is_mock_mode:
            # Return high-quality mock product data matching the real structure
            mock_products = [
                {
                    'product_code': '12345',
                    'name': 'Mock Premium Item A',
                    'barcode': '8901234567890',
                    'price_1': 100.0,
                    'price_2': 90.0,
                    'price_3': 80.0
                },
                {
                    'product_code': '67890',
                    'name': 'Mock Premium Item B',
                    'barcode': '8901234567891',
                    'price_1': 250.0,
                    'price_2': 230.0,
                    'price_3': 200.0
                },
                {
                    'product_code': '11111',
                    'name': 'Mock Wholesale Item C',
                    'barcode': '8901234567892',
                    'price_1': 50.0,
                    'price_2': 45.0,
                    'price_3': 40.0
                }
            ]

            # Resolve user's active price for the mock products
            for p in mock_products:
                if price_level == 2:
                    p['price'] = p['price_2']
                elif price_level == 3:
                    p['price'] = p['price_3']
                else:
                    p['price'] = p['price_1']

            if query:
                # Filter results based on search query (case-insensitive barcode or code match)
                q_lower = query.lower()
                filtered = [
                    p for p in mock_products
                    if q_lower in p['product_code'].lower() or q_lower in p['barcode'].lower() or q_lower in p['name'].lower()
                ]
                return Response(filtered)
            
            return Response(mock_products)

        try:
            conn = get_mssql_connection()
        except RuntimeError as exc:
            # SQL Server is unreachable — return a clear error so the app can
            # display an appropriate offline message.
            return Response(
                {'error': str(exc), 'detail': 'Billing database unavailable. (To test from home without SQL Server, set MOCK_DATABASE=True in .env)'},
                status=503
            )

        try:
            cursor = conn.cursor()

            if query.strip():
                # Parametrised search by product code OR barcode
                cursor.execute(self._SEARCH_SQL, (query, query))
            else:
                # No query — return sample browse list (first 30 products)
                cursor.execute(self._BROWSE_SQL)

            rows = cursor.fetchall()
            results = [self._row_to_dict(row, price_level) for row in rows]
            return Response(results)

        except Exception as exc:
            return Response(
                {'error': f'Query failed: {str(exc)}'},
                status=500
            )
        finally:
            # Always close the connection to avoid connection pool exhaustion
            try:
                conn.close()
            except Exception:
                pass


class RegisterUserView(generics.CreateAPIView):
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user.profile

class IncrementSearchView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile = request.user.profile
        profile.searches_today += 1
        profile.save()
        return Response({'searches_today': profile.searches_today})

class AdminSetupCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from django.contrib.auth.models import User
        admin_exists = User.objects.filter(is_superuser=True).exists()
        return Response({'admin_exists': admin_exists})

class AdminSetupView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from django.contrib.auth.models import User
        if User.objects.filter(is_superuser=True).exists():
            return Response({'error': 'Initial setup already completed.'}, status=403)
        
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_staff = True
            user.is_superuser = True
            user.save()
            
            # Ensure the admin's profile is approved since the signal
            # runs before we set is_superuser to True.
            profile = user.profile
            profile.is_approved = True
            profile.save()
            
            return Response({'message': 'Admin account created successfully.'}, status=201)
        return Response(serializer.errors, status=400)

class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from django.contrib.auth.models import User
        from django.core.mail import send_mail
        import random
        from django.utils import timezone
        from datetime import timedelta
        
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required.'}, status=400)
            
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({'error': 'No account found with this email address.'}, status=404)
            
        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))
        
        # Save OTP and expiry (15 mins) to user profile
        try:
            profile = user.profile
            profile.reset_otp = otp
            profile.reset_otp_expiry = timezone.now() + timedelta(minutes=15)
            profile.save()
        except Exception as e:
            return Response({'error': 'User profile setup incomplete.'}, status=500)
        
        from django.conf import settings
        import smtplib
        from django.core.mail import send_mail
        
        try:
            send_mail(
                'Your Password Reset OTP',
                f'Your One-Time Password (OTP) to reset your password is: {otp}\n\nThis OTP is valid for 15 minutes. Please do not share it with anyone.',
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
        except smtplib.SMTPException as e:
            return Response({'error': 'Failed to send email. Please check your SMTP configuration.'}, status=500)
        except Exception as e:
            return Response({'error': f'An error occurred while sending the email: {str(e)}'}, status=500)
            
        return Response({'message': 'An OTP has been sent to your email.'})

class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from django.contrib.auth.models import User
        from django.utils import timezone
        
        email = request.data.get('email')
        otp = request.data.get('otp')
        new_password = request.data.get('password')
        
        if not all([email, otp, new_password]):
            return Response({'error': 'Email, OTP, and new password are required.'}, status=400)
            
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({'error': 'Invalid email or OTP.'}, status=400)
            
        try:
            profile = user.profile
        except Exception:
            return Response({'error': 'User profile not found.'}, status=400)
            
        if profile.reset_otp != otp:
            return Response({'error': 'Invalid OTP.'}, status=400)
            
        if not profile.reset_otp_expiry or timezone.now() > profile.reset_otp_expiry:
            return Response({'error': 'OTP has expired.'}, status=400)
            
        # Reset password
        user.set_password(new_password)
        user.save()
        
        # Clear OTP
        profile.reset_otp = None
        profile.reset_otp_expiry = None
        profile.save()
        
        return Response({'message': 'Password has been reset successfully.'})

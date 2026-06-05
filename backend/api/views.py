from rest_framework import generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from .serializers import UserRegistrationSerializer, UserProfileSerializer
from rest_framework.exceptions import NotFound
from .mssql_client import search_products


class ProductSearchView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('query')
        code = request.query_params.get('code')
        
        search_term = query if query is not None else code
        if search_term:
            search_term = search_term.strip()
            
        try:
            raw_results = search_products(search_term)
            
            price_level = 1
            try:
                price_level = request.user.profile.price_level
            except Exception:
                pass
                
            results = []
            for row in raw_results:
                price_1 = float(row.get('price a') or 0.0)
                price_2 = float(row.get('price b') or 0.0)
                price_3 = float(row.get('price c') or 0.0)
                
                # Determine active price based on user level
                if price_level == 1:
                    price = price_1
                elif price_level == 2:
                    price = price_2
                elif price_level == 3:
                    price = price_3
                else:
                    price = price_1
                    
                results.append({
                    'product_code': str(row.get('product code')) if row.get('product code') is not None else '',
                    'name': str(row.get('product name')) if row.get('product name') is not None else '',
                    'price_label': str(row.get('price label')) if row.get('price label') is not None else '',
                    'price_1': price_1,
                    'price_2': price_2,
                    'price_3': price_3,
                    'price': price,
                })
                
            return Response(results)
        except Exception as e:
            return Response(
                {'error': f"Failed to retrieve products from external database: {str(e)}"},
                status=503
            )




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

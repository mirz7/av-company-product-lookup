from rest_framework import generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Product
from .serializers import ProductSerializer, UserRegistrationSerializer, UserProfileSerializer
from rest_framework.exceptions import NotFound

class ProductSearchView(generics.ListAPIView):
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        query = self.request.query_params.get('query')
        code = self.request.query_params.get('code')
        
        # Support old frontend parameter 'code' for backward compatibility
        search_term = query if query else code
        
        if search_term:
            from django.db.models import Q
            queryset = Product.objects.filter(
                Q(product_code__icontains=search_term) | Q(name__icontains=search_term)
            )
            return queryset
        
        # Return initial products (first 20) when no query is provided
        return Product.objects.all()[:30]

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

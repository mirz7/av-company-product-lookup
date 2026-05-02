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
        code = self.request.query_params.get('code')
        if code:
            queryset = Product.objects.filter(product_code=code)
            if not queryset.exists():
                raise NotFound(detail="Product not found")
            return queryset
        return Product.objects.none()

class FrequentProductsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        products = Product.objects.all()[:6]
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)

class RegisterUserView(generics.CreateAPIView):
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user.profile

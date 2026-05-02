from django.urls import path
from .views import ProductSearchView, RegisterUserView, UserProfileView, FrequentProductsView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('register/', RegisterUserView.as_view(), name='register'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('products/', ProductSearchView.as_view(), name='product_search'),
    path('products/frequent/', FrequentProductsView.as_view(), name='frequent_products'),
]

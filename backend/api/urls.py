from django.urls import path
from .views import ProductSearchView, RegisterUserView, UserProfileView, IncrementSearchView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('register/', RegisterUserView.as_view(), name='register'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('profile/increment-search/', IncrementSearchView.as_view(), name='increment_search'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('products/', ProductSearchView.as_view(), name='product_search'),
]

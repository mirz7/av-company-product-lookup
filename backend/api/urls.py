from django.urls import path
from .views import ProductSearchView, RegisterUserView, UserProfileView, IncrementSearchView
from .admin_views import (
    AdminDashboardView, AdminEmployeeListView, AdminEmployeeDetailView,
    AdminApprovalsView, AdminApproveEmployeeView, AdminRejectEmployeeView,
    AdminNotificationListView, AdminNotificationMarkReadView,
    AuthMeView,
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    # Auth
    path('register/', RegisterUserView.as_view(), name='register'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', AuthMeView.as_view(), name='auth_me'),

    # User profile (staff app)
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('profile/increment-search/', IncrementSearchView.as_view(), name='increment_search'),

    # Products
    path('products/', ProductSearchView.as_view(), name='product_search'),

    # Admin endpoints
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin_dashboard'),
    path('admin/employees/', AdminEmployeeListView.as_view(), name='admin_employees'),
    path('admin/employees/<int:pk>/', AdminEmployeeDetailView.as_view(), name='admin_employee_detail'),
    path('admin/approvals/', AdminApprovalsView.as_view(), name='admin_approvals'),
    path('admin/approvals/<int:pk>/approve/', AdminApproveEmployeeView.as_view(), name='admin_approve'),
    path('admin/approvals/<int:pk>/reject/', AdminRejectEmployeeView.as_view(), name='admin_reject'),
    path('admin/notifications/', AdminNotificationListView.as_view(), name='admin_notifications'),
    path('admin/notifications/<int:pk>/mark-read/', AdminNotificationMarkReadView.as_view(), name='admin_mark_read'),
]

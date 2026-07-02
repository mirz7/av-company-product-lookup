from django.urls import path
from . import views

app_name = "upload"

urlpatterns = [
    path("",           views.portal_dashboard, name="dashboard"),
    path("products/",  views.portal_products,  name="products"),
    path("login/",     views.portal_login,     name="login"),
    path("logout/",    views.portal_logout,    name="logout"),
]

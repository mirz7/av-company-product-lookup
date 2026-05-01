import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import Product

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')

if not Product.objects.exists():
    Product.objects.create(product_code='12345', price=10.99)
    Product.objects.create(product_code='67890', price=20.50)
    Product.objects.create(product_code='11111', price=5.00)

print("Data setup complete")

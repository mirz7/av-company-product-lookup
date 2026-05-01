import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import Product, UserProfile

# Create admin user if doesn't exist
if not User.objects.filter(username='admin').exists():
    admin_user = User.objects.create_superuser('admin', 'admin@example.com', 'admin')
else:
    admin_user = User.objects.get(username='admin')

# Ensure all users have a profile
for user in User.objects.all():
    UserProfile.objects.get_or_create(user=user, defaults={'price_level': 1})

# Delete old products if they don't have the new fields (optional, but good for clean state)
# Actually, migration will just add the fields with default 0.00. We can just update them.

if not Product.objects.filter(product_code='12345').exists():
    Product.objects.create(product_code='12345', price_1=10.99, price_2=9.99, price_3=8.99)
else:
    p = Product.objects.get(product_code='12345')
    p.price_1 = 10.99
    p.price_2 = 9.99
    p.price_3 = 8.99
    p.save()

if not Product.objects.filter(product_code='67890').exists():
    Product.objects.create(product_code='67890', price_1=20.50, price_2=18.50, price_3=15.00)
else:
    p = Product.objects.get(product_code='67890')
    p.price_1 = 20.50
    p.price_2 = 18.50
    p.price_3 = 15.00
    p.save()

if not Product.objects.filter(product_code='11111').exists():
    Product.objects.create(product_code='11111', price_1=5.00, price_2=4.50, price_3=4.00)
else:
    p = Product.objects.get(product_code='11111')
    p.price_1 = 5.00
    p.price_2 = 4.50
    p.price_3 = 4.00
    p.save()

print("Data setup complete with multi-pricing.")

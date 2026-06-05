import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile

# Create admin user if doesn't exist
if not User.objects.filter(username='admin').exists():
    admin_user = User.objects.create_superuser('admin', 'admin@example.com', 'admin')
else:
    admin_user = User.objects.get(username='admin')

# Ensure all users have a profile
for user in User.objects.all():
    UserProfile.objects.get_or_create(user=user, defaults={'price_level': 1})

print("Data setup complete.")

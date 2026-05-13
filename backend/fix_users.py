from django.contrib.auth.models import User
from api.models import UserProfile

for user in User.objects.all():
    user.is_active = True
    user.save()
    print(f"Set is_active=True for {user.username}")

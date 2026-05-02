from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    PRICE_LEVEL_CHOICES = [
        (1, 'Price Level 1 (Standard)'),
        (2, 'Price Level 2 (Discount)'),
        (3, 'Price Level 3 (Wholesale)'),
    ]
    price_level = models.IntegerField(choices=PRICE_LEVEL_CHOICES, default=1)
    role = models.CharField(max_length=50, default='Sales')
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    profile_photo = models.URLField(max_length=500, blank=True, null=True, default='https://ui-avatars.com/api/?name=User&background=random')
    def __str__(self):
        return f"{self.user.username} - Level {self.price_level}"

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()

class Product(models.Model):
    product_code = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=200, blank=True, default='')
    price_1 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 1")
    price_2 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 2")
    price_3 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 3")

    def __str__(self):
        return f"{self.name or self.product_code}"

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
    is_approved = models.BooleanField(default=False)  # Admin must approve; employee can still log in
    role = models.CharField(max_length=50, default='Sales')
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    profile_photo = models.ImageField(upload_to='profiles/', blank=True, null=True)
    searches_today = models.IntegerField(default=0)
    hours_logged = models.DecimalField(max_digits=5, decimal_places=1, default=0.0)
    is_active = models.BooleanField(default=True) # Custom active status to allow login while restricted
    
    # OTP for password reset
    reset_otp = models.CharField(max_length=6, blank=True, null=True)
    reset_otp_expiry = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} - Level {self.price_level}"

class AdminNotification(models.Model):
    NOTIFICATION_TYPES = [
        ('new_registration', 'New Staff Registration'),
        ('system_alert',     'System Alert'),
    ]
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES, default='new_registration')
    title = models.CharField(max_length=200)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    related_user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.title} - {'Read' if self.is_read else 'Unread'}"

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        # Superusers are auto-approved; regular staff start as pending
        is_approved = instance.is_superuser or instance.is_staff
        UserProfile.objects.create(user=instance, is_approved=is_approved)
        
        # If it's a new non-approved user (staff registration), notify admins
        if not is_approved:
            AdminNotification.objects.create(
                title="New Staff Registration",
                message=f"New staff member '{instance.username}' has registered and is awaiting approval.",
                related_user=instance,
                notification_type='new_registration'
            )

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    try:
        instance.profile.save()
    except UserProfile.DoesNotExist:
        pass

class Product(models.Model):
    product_code = models.CharField(max_length=100, unique=True, db_column='item_code')
    name = models.CharField(max_length=200, blank=True, default='', db_column='item_name')
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Cost Price", db_column='cost_price')
    price_1 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 1", db_column='price_a')
    price_2 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 2", db_column='price_b')
    price_3 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Price 3", db_column='price_c')

    class Meta:
        db_table = 'products'
        managed = False

    def __str__(self):
        return f"{self.name or self.product_code}"


class ActivityLog(models.Model):
    ACTIVITY_TYPES = [
        ('employee_onboarded', 'Employee Onboarded'),
        ('access_change',      'Access Change'),
        ('profile_update',     'Profile Update'),
        ('inventory_audit',    'Inventory Audit'),
        ('policy_update',      'Policy Update'),
        ('data_sync',          'Data Sync'),
        ('employee_approved',  'Employee Approved'),
        ('employee_rejected',  'Employee Rejected'),
    ]
    activity_type = models.CharField(max_length=50, choices=ACTIVITY_TYPES)
    title    = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=300, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.activity_type}] {self.title}"
class FCMToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='fcm_tokens')
    token = models.CharField(max_length=500, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f'{self.user.username} - {self.token[:20]}...'

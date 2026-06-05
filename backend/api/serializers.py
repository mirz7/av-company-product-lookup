from rest_framework import serializers
from .models import AdminNotification

class AdminNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminNotification
        fields = ['id', 'notification_type', 'title', 'message', 'timestamp', 'is_read', 'related_user']




from django.contrib.auth.models import User
from .models import UserProfile

class UserProfileSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    is_approved = serializers.BooleanField(read_only=True)
    profile_photo_url = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['username', 'first_name', 'last_name', 'email', 'role',
                  'phone_number', 'profile_photo', 'profile_photo_url',
                  'price_level', 'searches_today', 'hours_logged',
                  'is_approved', 'is_active']

    def get_profile_photo_url(self, obj):
        request = self.context.get('request')
        if obj.profile_photo and request:
            return request.build_absolute_uri(obj.profile_photo.url)
        return None


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    role = serializers.CharField(write_only=True, required=False)
    phone_number = serializers.CharField(write_only=True, required=False)
    email = serializers.EmailField(required=False)

    class Meta:
        model = User
        fields = ['username', 'password', 'first_name', 'last_name', 'email', 'role', 'phone_number']

    def create(self, validated_data):
        role = validated_data.pop('role', 'Sales')
        phone_number = validated_data.pop('phone_number', '')
        # is_active=True so employee can log in immediately after registering
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            email=validated_data.get('email', ''),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            is_active=True,
        )
        # Profile is created via signal with is_approved=False by default
        user.profile.role = role
        user.profile.phone_number = phone_number
        user.profile.save()
        return user


class AdminEmployeeSerializer(serializers.ModelSerializer):
    """Serializer used by admin endpoints to manage employees."""
    job_role = serializers.SerializerMethodField()
    permission_level = serializers.SerializerMethodField()
    price_b_access = serializers.SerializerMethodField()
    price_c_access = serializers.SerializerMethodField()
    is_approved = serializers.SerializerMethodField()
    is_active = serializers.SerializerMethodField()
    profile_photo_url = serializers.SerializerMethodField()
    phone_number = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name',
                  'is_active', 'is_approved', 'job_role', 'permission_level',
                  'price_b_access', 'price_c_access', 'profile_photo_url', 'phone_number', 'date_joined']

    def get_job_role(self, obj):
        try:
            return obj.profile.role or 'Staff'
        except Exception:
            return 'Staff'

    def get_permission_level(self, obj):
        try:
            level = obj.profile.price_level
            return {1: 'standard', 2: 'discount', 3: 'wholesale'}.get(level, 'standard')
        except Exception:
            return 'standard'

    def get_price_b_access(self, obj):
        try:
            return obj.profile.price_level >= 2
        except Exception:
            return False

    def get_price_c_access(self, obj):
        try:
            return obj.profile.price_level >= 3
        except Exception:
            return False

    def get_is_approved(self, obj):
        try:
            return obj.profile.is_approved
        except Exception:
            return False

    def get_is_active(self, obj):
        try:
            return obj.profile.is_active
        except Exception:
            return True

    def get_profile_photo_url(self, obj):
        request = self.context.get('request')
        try:
            if obj.profile.profile_photo and request:
                return request.build_absolute_uri(obj.profile.profile_photo.url)
        except Exception:
            pass
        return None

    def get_phone_number(self, obj):
        try:
            return obj.profile.phone_number
        except Exception:
            return None
from .models import FCMToken

class FCMTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = FCMToken
        fields = ['token']

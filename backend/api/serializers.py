from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    price = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['product_code', 'name', 'price', 'cost_price', 'price_1', 'price_2', 'price_3']

    def get_price(self, obj):
        # Get the requested user
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            try:
                # Based on user's price level, return the correct price
                level = request.user.profile.price_level
                if level == 1:
                    return obj.price_1
                elif level == 2:
                    return obj.price_2
                elif level == 3:
                    return obj.price_3
            except Exception:
                pass
        # Fallback to price_1
        return obj.price_1

from django.contrib.auth.models import User
from .models import UserProfile

class UserProfileSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)

    total_products = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['username', 'first_name', 'last_name', 'email', 'role', 'phone_number', 'profile_photo', 'price_level', 'searches_today', 'hours_logged', 'total_products']

    def get_total_products(self, obj):
        from .models import Product
        return Product.objects.count()

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
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            email=validated_data.get('email', ''),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        # Profile is created via signals, so update it
        user.profile.role = role
        user.profile.phone_number = phone_number
        user.profile.save()
        return user

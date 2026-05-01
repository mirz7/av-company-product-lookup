from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    price = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['product_code', 'price']

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

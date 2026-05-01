from django.db import models

class Product(models.Model):
    product_code = models.CharField(max_length=100, unique=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.product_code} - ${self.price}"

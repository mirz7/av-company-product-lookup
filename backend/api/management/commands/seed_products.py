from django.core.management.base import BaseCommand
from api.models import Product

DEMO_PRODUCTS = [
    {"product_code": "CF-9021", "name": "Ceiling Fan 900mm", "price_1": 45.99, "price_2": 40.99, "price_3": 36.99},
    {"product_code": "WB-1200", "name": "Wire Bundle 1.2m", "price_1": 12.50, "price_2": 10.99, "price_3": 9.25},
    {"product_code": "LED-50W", "name": "LED Bulb 50W White", "price_1": 8.99, "price_2": 7.50, "price_3": 6.25},
    {"product_code": "SW-2G-W", "name": "Switch 2-Gang White", "price_1": 6.75, "price_2": 5.99, "price_3": 5.00},
    {"product_code": "CB-16A",  "name": "Circuit Breaker 16A", "price_1": 18.50, "price_2": 16.75, "price_3": 14.50},
    {"product_code": "EXT-5M",  "name": "Extension Cord 5M 3-Pin", "price_1": 22.00, "price_2": 19.50, "price_3": 17.00},
    {"product_code": "PVC-20",  "name": "PVC Conduit 20mm 3M", "price_1": 3.75, "price_2": 3.25, "price_3": 2.80},
    {"product_code": "DB-8W",   "name": "Distribution Board 8-Way", "price_1": 75.00, "price_2": 67.50, "price_3": 60.00},
    {"product_code": "SOC-3P",  "name": "Socket 3-Pin Switched", "price_1": 5.50, "price_2": 4.75, "price_3": 4.00},
    {"product_code": "CAB-NYY", "name": "Cable NYY 2.5mm x 4C", "price_1": 3.20, "price_2": 2.85, "price_3": 2.50},
]

class Command(BaseCommand):
    help = 'Seed demo products into the database'

    def handle(self, *args, **kwargs):
        created = 0
        updated = 0
        for item in DEMO_PRODUCTS:
            obj, was_created = Product.objects.update_or_create(
                product_code=item["product_code"],
                defaults={
                    "price_1": item["price_1"],
                    "price_2": item["price_2"],
                    "price_3": item["price_3"],
                }
            )
            if was_created:
                created += 1
            else:
                updated += 1
        self.stdout.write(self.style.SUCCESS(f'✅ Seeded {created} new products, updated {updated} existing.'))

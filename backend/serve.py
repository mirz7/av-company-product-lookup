from waitress import serve
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

from django.core.wsgi import get_wsgi_application

application = get_wsgi_application()

if __name__ == "__main__":
    print("Starting Waitress server on http://0.0`.0.0:8000 ...")
    print("Press Ctrl+C to stop.")
    serve(application, host="0.0.0.0", port=8000)
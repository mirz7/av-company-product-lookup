import os
import sys

# Add the project directory to python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Set environment variable for Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Initialize Django
import django
django.setup()

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description="Run the Django WSGI application.")
    parser.add_argument('--host', type=str, default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8000, help='Port to bind to')
    parser.add_argument('--server', type=str, default='waitress', choices=['waitress', 'wsgiref'], help='WSGI server to use')
    
    args = parser.parse_args()
    
    print(f"Starting WSGI runner for Django...")
    print(f"Host: {args.host}")
    print(f"Port: {args.port}")
    
    if args.server == 'waitress':
        try:
            from waitress import serve
            print("Using Waitress WSGI server.")
            serve(application, host=args.host, port=args.port)
        except ImportError:
            print("Waitress not installed. Installing waitress...")
            import subprocess
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "waitress"])
                from waitress import serve
                print("Waitress installed successfully! Starting server...")
                serve(application, host=args.host, port=args.port)
            except Exception as e:
                print(f"Failed to install/run waitress: {e}")
                print("Falling back to Python's built-in wsgiref simple_server...")
                from wsgiref.simple_server import make_server
                httpd = make_server(args.host, args.port, application)
                httpd.serve_forever()
    else:
        from wsgiref.simple_server import make_server
        print("Using Python's built-in wsgiref simple_server (not recommended for production).")
        httpd = make_server(args.host, args.port, application)
        httpd.serve_forever()

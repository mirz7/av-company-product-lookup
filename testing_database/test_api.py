import json
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import db_connection

class TestApiRequestHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers to every response to avoid browser security blocks
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PATCH, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

    def do_OPTIONS(self):
        # Handle pre-flight CORS requests
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path
        query_params = urllib.parse.parse_qs(parsed_url.query)

        # ── Endpoint: GET /test/products ──────────────────────────────
        if path == '/test/products' or path == '/test/products/':
            # Extract query search parameter (matches Flutter searchProducts behaviour)
            search_query = query_params.get('query', [''])[0].strip().lower()
            if not search_query:
                # Also accept standard legacy parameter '?code='
                search_query = query_params.get('code', [''])[0].strip().lower()

            products = db_connection.get_all_products()
            mapped_products = [self.map_db_row_to_api(p) for p in products]

            if search_query:
                # Filter results based on search query
                filtered_products = []
                for p in mapped_products:
                    # Match by barcode, product code, or product name
                    if (search_query in p['product_code'].lower() or
                        search_query in p['barcode'].lower() or
                        search_query in p['name'].lower()):
                        filtered_products.append(p)
                mapped_products = filtered_products

            self.send_json_response(200, mapped_products)
            return

        # ── Endpoint: GET /test/product/code/<product_code> ───────────
        elif path.startswith('/test/product/code/'):
            product_code = path.replace('/test/product/code/', '').strip('/')
            product = db_connection.get_product_by_code(product_code)
            if product:
                self.send_json_response(200, self.map_db_row_to_api(product))
            else:
                self.send_json_response(404, {'error': f'Product with code {product_code} not found'})
            return

        # ── Endpoint: GET /test/product/barcode/<barcode> ─────────────
        elif path.startswith('/test/product/barcode/'):
            barcode = path.replace('/test/product/barcode/', '').strip('/')
            product = db_connection.get_product_by_barcode(barcode)
            if product:
                self.send_json_response(200, self.map_db_row_to_api(product))
            else:
                self.send_json_response(404, {'error': f'Product with barcode {barcode} not found'})
            return

        # ── Endpoint Fallback ─────────────────────────────────────────
        else:
            self.send_json_response(404, {'error': 'Endpoint not found', 'path': path})

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path

        # ── Endpoint: POST /test/product/update ────────────────────────
        if path == '/test/product/update' or path == '/test/product/update/':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)

            try:
                data = json.loads(post_data.decode('utf-8'))
            except Exception:
                # Fallback to form urlencoded if JSON parsing fails
                try:
                    data = {k: v[0] for k, v in urllib.parse.parse_qs(post_data.decode('utf-8')).items()}
                except Exception:
                    self.send_json_response(400, {'error': 'Invalid request body. Expected JSON.'})
                    return

            product_code = data.get('product_code') or data.get('ProductCode')
            new_price = data.get('price') or data.get('Price1') or data.get('price_1')

            if not product_code or new_price is None:
                self.send_json_response(400, {'error': 'Missing required fields: product_code and price'})
                return

            try:
                success = db_connection.update_product_price(product_code, new_price)
                if success:
                    updated_product = db_connection.get_product_by_code(product_code)
                    self.send_json_response(200, {
                        'success': True,
                        'message': f'Product {product_code} price updated successfully to {new_price}',
                        'product': self.map_db_row_to_api(updated_product)
                    })
                else:
                    self.send_json_response(404, {'error': f'Product {product_code} not found in database'})
            except Exception as e:
                self.send_json_response(500, {'error': f'Database update failed: {str(e)}'})
            return

        else:
            self.send_json_response(404, {'error': 'Endpoint not found', 'path': path})

    def send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        response_bytes = json.dumps(data, indent=2).encode('utf-8')
        self.send_header('Content-Length', str(len(response_bytes)))
        self.end_headers()
        self.wfile.write(response_bytes)

    def map_db_row_to_api(self, row):
        """
        Converts SQLite Row (TitleCase fields) into API dict response (snake_case fields)
        matching the field format expected by the Flutter app's Product model.
        """
        if not row:
            return {}
        
        price_1 = float(row.get('Price1') or 0.0)
        price_2 = float(row.get('Price2') or 0.0)
        price_3 = float(row.get('Price3') or 0.0)

        return {
            'product_code': str(row.get('ProductCode') or ''),
            'name':         str(row.get('ProductName') or ''),
            'barcode':      str(row.get('Barcode') or ''),
            'price':        price_1,          # default solved price
            'price_1':      price_1,          # Price A
            'price_2':      price_2,          # Price B
            'price_3':      price_3,          # Price C
            'brand':        str(row.get('BrandName') or ''),
            'category':     str(row.get('CategoryName') or ''),
            'stock':        int(row.get('Stock') or 0),
            'is_active':    bool(row.get('IsActive') or False)
        }

def run_server(port=8001):
    db_connection.init_db()  # Ensure database exists and is seeded
    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, TestApiRequestHandler)
    print(f"Isolated Testing DB API server is running on http://0.0.0.0:{port}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping testing API server...")
        httpd.server_close()

if __name__ == '__main__':
    run_server()

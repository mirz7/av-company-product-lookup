# Isolated Testing Database Environment

This folder contains a completely isolated SQLite database and Python-based REST API server. It is built to simulate a client billing database and test the synchronization and real-time database synchronization capabilities of the Staff Product Lookup application.

---

## Folder Contents

- `database.db`: The local SQLite database file containing the `Products` table.
- `sample_products.sql`: SQL script containing the table schema and 5 seed products.
- `db_connection.py`: Reusable Python database access layer containing CRUD functions.
- `test_api.py`: Portable zero-dependency REST API server running on port `8001`.
- `README.md`: This step-by-step verification guide.

---

## Setup & Running the Testing API Server

1. **Prerequisites**: Python 3.x must be installed. No extra `pip` packages are required (runs on built-in libraries!).
2. **Launch the Server**:
   Open a terminal in the `/testing_database` folder and run:
   ```bash
   python test_api.py
   ```
   *Note: This will automatically initialize the `database.db` and insert seed data if the database doesn't exist.*
   *The server binds to `0.0.0.0:8001`, making it reachable over your local network/Wi-Fi.*

---

## Testing API Endpoints

Once the server is running, the following endpoints are available:

### 1. Get All Products (supports optional search query)
- **Endpoint**: `GET /test/products`
- **With search query**: `GET /test/products?query=Dove` (Searches by ProductCode, Barcode, or ProductName)
- **Response Format**: List of JSON objects in snake_case (matching Flutter expectation):
  ```json
  [
    {
      "product_code": "10001",
      "name": "Dove Soap 100g",
      "barcode": "890100000001",
      "price": 45.0,
      "price_1": 45.0,
      "price_2": 42.0,
      "price_3": 40.0,
      "brand": "Dove",
      "category": "Personal Care",
      "stock": 100,
      "is_active": true
    }
  ]
  ```

### 2. Get Product by Code
- **Endpoint**: `GET /test/product/code/<product_code>` (e.g. `/test/product/code/10002`)

### 3. Get Product by Barcode
- **Endpoint**: `GET /test/product/barcode/<barcode>` (e.g. `/test/product/barcode/890100000004`)

### 4. Update Product Price (POST)
- **Endpoint**: `POST /test/product/update`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "product_code": "10002",
    "price": 130.0
  }
  ```

---

## Step-by-Step Sync Verification Guide

### Test 1: Real-time Price Update Verification

1. **Step 1**: Start the test API server: `python test_api.py` (ensure port `8001` is open).
2. **Step 2**: Open `database.db` using any SQLite viewer (e.g. DB Browser for SQLite, VS Code SQLite extension) or execute this python command:
   ```bash
   python -c "import db_connection; db_connection.update_product_price('10002', 130.0)"
   ```
   *(This updates the standard Price1 of product `10002` (Colgate Toothpaste) from `120` to `130`)*
3. **Step 3**: Launch the Flutter application.
4. **Step 4**: Press the Search/Go button in the application (or pull-to-refresh).
5. **Expected Result**: Colgate Toothpaste immediately displays `₹130` in the UI without restarting the application!

---

### Test 2: Real-time Product Name Update Verification

1. **Step 1**: Run this python command to change the product name of code `10005`:
   ```bash
   python -c "import db_connection; conn = db_connection.get_connection(); conn.cursor().execute(\"UPDATE Products SET ProductName = 'Clinic Plus Strong Shampoo 180ml' WHERE ProductCode = '10005'\"); conn.commit(); conn.close()"
   ```
2. **Step 2**: In the app's product lookup screen, click the Search/Go button (Fetch) again.
3. **Expected Result**: The shampoo product immediately displays the new name `Clinic Plus Strong Shampoo 180ml` in the list, showing perfect and instant database synchronization!

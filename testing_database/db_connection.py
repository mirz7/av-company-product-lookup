import os
import sqlite3

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'database.db')
SQL_SCHEMA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sample_products.sql')

def get_connection():
    """Returns a connection to the SQLite testing database."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Access columns by name
    return conn

def init_db(force=False):
    """
    Initializes the database using sample_products.sql if database.db
    doesn't exist, is empty, or if sample_products.sql has been modified.
    """
    db_exists = os.path.exists(DB_PATH) and os.path.getsize(DB_PATH) > 0
    sql_exists = os.path.exists(SQL_SCHEMA_PATH)
    
    needs_init = force or not db_exists
    
    if db_exists and sql_exists:
        try:
            sql_mtime = os.path.getmtime(SQL_SCHEMA_PATH)
            db_mtime = os.path.getmtime(DB_PATH)
            if sql_mtime > db_mtime:
                needs_init = True
                print("Detected changes in sample_products.sql. Automatically re-syncing database...")
        except Exception:
            pass

    if needs_init:
        print("Initializing testing SQLite database...")
        conn = get_connection()
        try:
            with open(SQL_SCHEMA_PATH, 'r') as f:
                sql_script = f.read()
            conn.executescript(sql_script)
            conn.commit()
            print("Testing database initialized successfully.")
        except Exception as e:
            print(f"Error initializing testing database: {e}")
        finally:
            conn.close()

def row_to_dict(row):
    """Helper to convert sqlite3.Row to standard dictionary."""
    if row is None:
        return None
    return dict(row)

def get_all_products():
    """Retrieve all products from the database."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Products")
        rows = cursor.fetchall()
        return [row_to_dict(r) for r in rows]
    finally:
        conn.close()

def get_product_by_code(product_code):
    """Retrieve a product by its ProductCode."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Products WHERE ProductCode = ?", (product_code,))
        row = cursor.fetchone()
        return row_to_dict(row)
    finally:
        conn.close()

def get_product_by_barcode(barcode):
    """Retrieve a product by its Barcode."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Products WHERE Barcode = ?", (barcode,))
        row = cursor.fetchone()
        return row_to_dict(row)
    finally:
        conn.close()

def update_product_price(product_code, new_price):
    """Update the Price1 value of a product by ProductCode."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE Products SET Price1 = ? WHERE ProductCode = ?",
            (float(new_price), product_code)
        )
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

def insert_product(product_code, barcode, product_name, price1, price2, price3, brand_name, category_name, stock, is_active=1):
    """Insert a new product into the database."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (product_code, barcode, product_name, float(price1), float(price2), float(price3), brand_name, category_name, int(stock), int(is_active))
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()

def delete_product(product_code):
    """Delete a product by ProductCode."""
    init_db()
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM Products WHERE ProductCode = ?", (product_code,))
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()

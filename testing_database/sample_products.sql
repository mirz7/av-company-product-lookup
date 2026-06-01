-- SQLite schema and seed data for isolated testing database

CREATE TABLE IF NOT EXISTS Products (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductCode TEXT UNIQUE,
    Barcode TEXT UNIQUE,
    ProductName TEXT,
    Price1 REAL,
    Price2 REAL,
    Price3 REAL,
    BrandName TEXT,
    CategoryName TEXT,
    Stock INTEGER,
    IsActive INTEGER DEFAULT 1
);

-- Insert sample data
INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10001', '890100000001', 'Dove Soap 100g', 45.0, 42.0, 40.0, 'Dove', 'Personal Care', 100, 1);

INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10002', '890100000002', 'Colgate Toothpaste 200g', 120.0, 115.0, 110.0, 'Colgate', 'Oral Care', 50, 1);

INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10003', '890100000003', 'Lux Soap Rose 150g', 55.0, 50.0, 48.0, 'Lux', 'Personal Care', 75, 1);

INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10004', '890100000004', 'Dettol Handwash 250ml', 99.0, 95.0, 90.0, 'Dettol', 'Hygiene', 30, 1);

INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10005', '890100000005', 'Clinic Plus Shampoo 180ml', 145.0, 140.0, 135.0, 'Clinic Plus', 'Hair Care', 20, 1);

INSERT OR REPLACE INTO Products (ProductCode, Barcode, ProductName, Price1, Price2, Price3, BrandName, CategoryName, Stock, IsActive)
VALUES ('10006', '890100000006', 'Clinic Plus Strong 180ml', 130.0, 120.0, 115.0, 'Clinic Plus', 'Hair Care', 30, 1);

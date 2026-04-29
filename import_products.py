import pandas as pd
from sqlalchemy import create_engine

# ── MySQL credentials ──────────────────────
DB_HOST = "localhost"
DB_PORT = "3306"
DB_USER = "root"
DB_PASS = ""  # ← change this
DB_NAME = "myapp_db"
# ───────────────────────────────────────────

# Connect to MySQL
engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# Read Excel file
df = pd.read_excel("products.xlsx")

# Check what columns were detected
print("Columns found:", df.columns.tolist())
print("Total rows:", len(df))

# Rename columns to match DB table
df.columns = [
    'sl_no', 'item_code', 'item_name',
    'unit_name', 'cost_price',
    'price_a', 'price_b', 'price_c'
]

# Clean data — remove completely empty rows
df = df.dropna(subset=['item_code'])

# Make sure price columns are numbers
df['cost_price'] = pd.to_numeric(
    df['cost_price'], errors='coerce').fillna(0)
df['price_a'] = pd.to_numeric(
    df['price_a'], errors='coerce').fillna(0)
df['price_b'] = pd.to_numeric(
    df['price_b'], errors='coerce').fillna(0)
df['price_c'] = pd.to_numeric(
    df['price_c'], errors='coerce').fillna(0)

# Upload to MySQL
df.to_sql(
    name='products',        # table name
    con=engine,
    if_exists='append',     # append = add rows, replace = overwrite all
    index=False             # don't add pandas index as a column
)

print(f"✅ {len(df)} rows uploaded to MySQL successfully!")
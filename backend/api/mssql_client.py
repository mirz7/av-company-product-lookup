import os
import pyodbc
import logging

logger = logging.getLogger(__name__)

def get_best_odbc_driver():
    """
    Scans the system to find the best available SQL Server ODBC driver.
    """
    try:
        drivers = pyodbc.drivers()
        # Prefer ODBC Driver 18, 17, or fallback to the legacy SQL Server driver
        for d in ['ODBC Driver 18 for SQL Server', 'ODBC Driver 17 for SQL Server', 'SQL Server']:
            if d in drivers:
                return d
        # Find any other driver containing SQL Server
        for d in drivers:
            if 'SQL Server' in d or 'MSSQL' in d:
                return d
    except Exception as e:
        logger.warning(f"Failed to fetch ODBC drivers: {e}")
    return 'SQL Server'

def parse_connection_string(conn_str):
    """
    Parses a Microsoft SQL Server connection string of the form:
    "Server=localhost;Database=master;User Id=sa;Password=yourpassword;"
    """
    params = {}
    if not conn_str:
        return params
    
    conn_str = conn_str.strip().strip("'\"")
    parts = conn_str.split(';')
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if '=' in part:
            try:
                key, val = part.split('=', 1)
                key = key.strip().lower()
                val = val.strip().strip("'\"")
                params[key] = val
            except Exception as e:
                logger.warning(f"Failed to parse connection string component '{part}': {e}")
                
    server = params.get('server') or params.get('host') or 'localhost'
    database = params.get('database') or params.get('initial catalog') or 'master'
    user = params.get('user id') or params.get('uid') or params.get('user')
    password = params.get('password') or params.get('pwd')
    
    return {
        'server': server,
        'database': database,
        'user': user,
        'password': password,
    }

def get_mssql_connection():
    """
    Creates and returns a connection to the external Microsoft SQL Server using pyodbc.
    Automatically builds an ODBC connection string supporting both SQL Authentication and
    Windows Authentication (Trusted Connection).
    """
    conn_str = os.environ.get('MICROSOFT_SQL_SERVER_CONNECTION_STRING')
    if not conn_str:
        raise ValueError("MICROSOFT_SQL_SERVER_CONNECTION_STRING environment variable is not defined.")
        
    conn_str = conn_str.strip().strip("'\"")
    
    # If a full ODBC driver connection string is supplied directly, use it
    if 'driver=' in conn_str.lower():
        return pyodbc.connect(conn_str, timeout=10)
        
    params = parse_connection_string(conn_str)
    driver = get_best_odbc_driver()
    
    odbc_parts = [
        f"Driver={{{driver}}}",
        f"Server={params['server']}",
        f"Database={params['database']}"
    ]
    
    # ODBC Driver 18 defaults to encrypting connections, which fails with self-signed dev certificates.
    # We turn on TrustServerCertificate to avoid connection issues locally.
    if '18' in driver:
        odbc_parts.append("TrustServerCertificate=yes")
        
    # Choose between SQL Authentication and Windows Authentication
    if params['user'] and params['password']:
        odbc_parts.append(f"Uid={params['user']}")
        odbc_parts.append(f"Pwd={params['password']}")
    else:
        odbc_parts.append("Trusted_Connection=yes")
        
    odbc_conn_str = ";".join(odbc_parts)
    return pyodbc.connect(odbc_conn_str, timeout=10)

def get_total_products_count():
    """
    Queries the external database to count total items in [dbo].[ItemMaster].
    Returns 0 on failure.
    """
    try:
        with get_mssql_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM [dbo].[ItemMaster]")
                row = cursor.fetchone()
                return row[0] if row else 0
    except Exception as e:
        logger.error(f"Error fetching total products count from external MSSQL database: {e}")
        return 0

def search_products(search_term=None):
    """
    Queries the external database to find products.
    """
    base_query = """
    SELECT 
        im.[PluNo] AS [product code],
        im.[ItemName] AS [product name],
        pm.[DESCRIPTION] AS [price label],
        ip.[UnitPrice] AS [price a],
        ip.[PriceAmt] AS [price b],
        ip.[ChangeAmount] AS [price c]
    FROM [dbo].[ItemMaster] im
    INNER JOIN [dbo].[ItemMasterPriceFL] ip ON im.[ItmId] = ip.[ItmId]
    INNER JOIN [dbo].[PriceMaster] pm ON ip.[PriceId] = pm.[PriceId]
    """
    
    try:
        with get_mssql_connection() as conn:
            with conn.cursor() as cursor:
                if not search_term:
                    # Return top 30 products
                    query = f"SELECT TOP 30 * FROM ({base_query}) AS sub"
                    cursor.execute(query)
                    rows = cursor.fetchall()
                else:
                    # Check exact code match first
                    query = f"SELECT * FROM ({base_query}) AS sub WHERE [product code] = ?"
                    cursor.execute(query, (search_term,))
                    rows = cursor.fetchall()
                    
                    if not rows:
                        # Fallback to partial name/code matches
                        query = f"SELECT TOP 100 * FROM ({base_query}) AS sub WHERE [product code] LIKE ? OR [product name] LIKE ?"
                        like_term = f"%{search_term}%"
                        cursor.execute(query, (like_term, like_term))
                        rows = cursor.fetchall()
                
                # Convert pyodbc rows to dictionaries
                columns = [col[0] for col in cursor.description]
                results = []
                for row in rows:
                    results.append(dict(zip(columns, row)))
                return results
    except Exception as e:
        logger.error(f"Error querying products from external MSSQL database: {e}")
        raise

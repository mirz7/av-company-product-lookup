import os
import pymssql
import logging

logger = logging.getLogger(__name__)

def parse_connection_string(conn_str):
    """
    Parses a Microsoft SQL Server connection string of the form:
    "Server=localhost;Database=master;User Id=sa;Password=yourpassword;"
    or equivalent key-value pairs separated by semicolons.
    """
    params = {}
    if not conn_str:
        return params
    
    # Clean up outer quotes and whitespace
    conn_str = conn_str.strip().strip("'\"")
    
    # Split by semicolon
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
                
    # Normalize server / host and extract port if present
    server = params.get('server') or params.get('host') or 'localhost'
    port = 1433
    if ',' in server:
        server, port_str = server.split(',', 1)
        try:
            port = int(port_str.strip())
        except ValueError:
            pass
    elif ':' in server:
        server, port_str = server.split(':', 1)
        try:
            port = int(port_str.strip())
        except ValueError:
            pass
            
    # Normalize DB, User and Password
    database = params.get('database') or params.get('initial catalog') or 'master'
    user = params.get('user id') or params.get('uid') or params.get('user') or 'sa'
    password = params.get('password') or params.get('pwd') or ''
    
    return {
        'server': server,
        'user': user,
        'password': password,
        'database': database,
        'port': port,
    }

def get_mssql_connection():
    """
    Creates and returns a connection to the external Microsoft SQL Server.
    The connection settings are parsed from MICROSOFT_SQL_SERVER_CONNECTION_STRING.
    """
    conn_str = os.environ.get('MICROSOFT_SQL_SERVER_CONNECTION_STRING')
    if not conn_str:
        raise ValueError("MICROSOFT_SQL_SERVER_CONNECTION_STRING environment variable is not defined.")
        
    params = parse_connection_string(conn_str)
    
    # login_timeout prevents the API from hanging for a long time if server is offline
    return pymssql.connect(
        server=params['server'],
        user=params['user'],
        password=params['password'],
        database=params['database'],
        port=params['port'],
        login_timeout=5,
        timeout=10
    )

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
    Queries the external database using the specified query to find products.
    Supports:
    - Empty query: returns TOP 30 products.
    - Non-empty query: searches by exact code match, and if not found, partial matching.
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
            with conn.cursor(as_dict=True) as cursor:
                if not search_term:
                    # Return top 30 products
                    query = f"SELECT TOP 30 * FROM ({base_query}) AS sub"
                    cursor.execute(query)
                    return cursor.fetchall()
                
                # Check exact code match first
                query = f"SELECT * FROM ({base_query}) AS sub WHERE [product code] = %s"
                cursor.execute(query, (search_term,))
                results = cursor.fetchall()
                if results:
                    return results
                
                # Fallback to partial name/code matches
                query = f"SELECT TOP 100 * FROM ({base_query}) AS sub WHERE [product code] LIKE %s OR [product name] LIKE %s"
                like_term = f"%{search_term}%"
                cursor.execute(query, (like_term, like_term))
                return cursor.fetchall()
    except Exception as e:
        logger.error(f"Error querying products from external MSSQL database: {e}")
        raise

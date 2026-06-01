"""
mssql_connection.py
───────────────────
Provides a single helper function to obtain a live pyodbc connection to the
client's Microsoft SQL Server billing database.

Design decisions:
  • Keeps all SQL Server connectivity OUTSIDE Django's ORM so that Django's own
    migrations, admin, and auth tables stay on SQLite and are never affected.
  • Supports both SQL Server Authentication (username + password) and Windows
    Integrated Authentication (Trusted_Connection=yes) configured via .env.
  • Raises a descriptive RuntimeError if the connection cannot be established so
    callers can return a clean HTTP 503 instead of an unhandled traceback.
"""

import pyodbc
from django.conf import settings


def get_mssql_connection():
    """
    Return an open pyodbc connection to the SQL Server billing database.

    Connection parameters are read from Django settings, which in turn load
    them from the .env file:
        MSSQL_SERVER   – hostname or hostname\\instance (e.g. localhost\\SQLEXPRESS)
        MSSQL_PORT     – TCP port (default: 1433)
        MSSQL_DB_NAME  – database name in SQL Server
        MSSQL_USER     – SQL Server login (leave blank for Windows Auth)
        MSSQL_PASSWORD – password (leave blank for Windows Auth)
        MSSQL_DRIVER   – ODBC driver string (default: ODBC Driver 17 for SQL Server)

    Returns:
        pyodbc.Connection – an active database connection.

    Raises:
        RuntimeError – if the connection fails for any reason.
    """
    driver   = settings.MSSQL_DRIVER
    server   = settings.MSSQL_DB_SERVER
    port     = settings.MSSQL_DB_PORT
    database = settings.MSSQL_DB_NAME
    user     = settings.MSSQL_DB_USER
    password = settings.MSSQL_DB_PASSWORD

    # Build the ODBC connection string.
    # Use Windows Integrated Authentication when no username is configured.
    if user:
        # SQL Server Authentication (username + password)
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server},{port};"
            f"DATABASE={database};"
            f"UID={user};"
            f"PWD={password};"
        )
    else:
        # Windows Integrated Authentication — no credentials required
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server},{port};"
            f"DATABASE={database};"
            f"Trusted_Connection=yes;"
        )

    try:
        connection = pyodbc.connect(conn_str, timeout=5)
        return connection
    except pyodbc.Error as exc:
        raise RuntimeError(
            f"Cannot connect to SQL Server billing database: {exc}"
        ) from exc

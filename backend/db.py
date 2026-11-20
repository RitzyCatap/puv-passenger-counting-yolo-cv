import os

import psycopg
from dotenv import load_dotenv

load_dotenv(
    os.path.join(os.path.dirname(__file__), ".env"),
    override=True
)

def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        options=f"-c search_path={os.getenv('DB_SCHEMA', 'public')}"
    )
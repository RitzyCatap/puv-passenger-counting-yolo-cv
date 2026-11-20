
from fastapi import FastAPI
from db import get_connection
from app.api.routes import puvs

app = FastAPI(
    title="PUV Passenger Counting API",
    description=(
        "Backend API for Public Utility Vehicle Passenger "
        "Counting Using YOLO-Based Computer Vision"
    ),
    version="1.0.0"
)

app.include_router(puvs.router)

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/db-health")
def database_health_check():
    try:
        conn = get_connection()

        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1;")
                result = cursor.fetchone()

            return {
                "status": "connected",
                "database": "PostgreSQL",
                "result": result[0]
            }

        finally:
            conn.close()

    except Exception:
        return {
            "status": "error",
            "message": "Database connection failed"
        }
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db import get_connection
from app.api.routes import puvs, auth

app = FastAPI(
    title="PUV Passenger Counting API",
    description=(
        "Backend API for Public Utility Vehicle Passenger "
        "Counting Using YOLO-Based Computer Vision"
    ),
    version="1.0.0"
)


# ============================================================
# CORS CONFIGURATION
# Allows the local Flutter Web frontend to access the API.
# ============================================================

allowed_origins = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=[
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS",
    ],
    allow_headers=[
        "Accept",
        "Content-Type",
        "Authorization",
    ],
)


# ============================================================
# API ROUTES
# ============================================================

app.include_router(puvs.router)
app.include_router(auth.router)


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

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from psycopg.rows import dict_row

from db import get_connection

from app.core.authorization import (
    get_current_user,
    require_admin,
)


router = APIRouter(
    prefix="/puvs",
    tags=["PUV Management"],
)


class PUVCreate(BaseModel):
    puv_type: str = Field(min_length=1, max_length=50)
    capacity: int = Field(gt=0, le=2147483647)


class PUVUpdate(PUVCreate):
    pass


@router.get("/")
def get_puvs(
    current_user: dict = Depends(get_current_user),
):
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                SELECT puv_id, puv_type, capacity, created_at
                FROM passenger_counting.puvs_tbl
                ORDER BY puv_id
            """)

            return cursor.fetchall()


@router.get("/{puv_id}")
def get_puv(
    puv_id: int,
    current_user: dict = Depends(get_current_user),
):
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                SELECT puv_id, puv_type, capacity, created_at
                FROM passenger_counting.puvs_tbl
                WHERE puv_id = %s
            """, (puv_id,))

            puv = cursor.fetchone()

    if puv is None:
        raise HTTPException(
            status_code=404,
            detail="PUV not found",
        )

    return puv


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
)
def create_puv(
    data: PUVCreate,
    current_user: dict = Depends(require_admin),
):
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                INSERT INTO passenger_counting.puvs_tbl
                    (puv_type, capacity)
                VALUES (%s, %s)
                RETURNING puv_id, puv_type, capacity, created_at
            """, (data.puv_type, data.capacity))

            puv = cursor.fetchone()

    return puv


@router.put("/{puv_id}")
def update_puv(
    puv_id: int,
    data: PUVUpdate,
    current_user: dict = Depends(require_admin),
):
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                UPDATE passenger_counting.puvs_tbl
                SET puv_type = %s, capacity = %s
                WHERE puv_id = %s
                RETURNING puv_id, puv_type, capacity, created_at
            """, (
                data.puv_type,
                data.capacity,
                puv_id,
            ))

            puv = cursor.fetchone()

    if puv is None:
        raise HTTPException(
            status_code=404,
            detail="PUV not found",
        )

    return puv


@router.delete("/{puv_id}")
def delete_puv(
    puv_id: int,
    current_user: dict = Depends(require_admin),
):
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                DELETE FROM passenger_counting.puvs_tbl
                WHERE puv_id = %s
                RETURNING puv_id
            """, (puv_id,))

            deleted = cursor.fetchone()

    if deleted is None:
        raise HTTPException(
            status_code=404,
            detail="PUV not found",
        )

    return {"message": "PUV deleted successfully"}

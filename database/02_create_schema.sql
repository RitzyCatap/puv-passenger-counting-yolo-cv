-- ============================================================
-- PROJECT:
-- Public Utility Vehicle Passenger Counting
-- Using YOLO-Based Computer Vision
--
-- DATABASE:
-- puv_passenger_counting_db
--
-- SCHEMA:
-- passenger_counting
-- ============================================================


-- ============================================================
-- CREATE SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS passenger_counting;

SET search_path TO passenger_counting;


-- ============================================================
-- TABLE 1: users_tbl
--
-- Purpose:
-- Stores users who can access and manage the system.
-- ============================================================

CREATE TABLE users_tbl (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
    CONSTRAINT chk_user_role
        CHECK (role IN ('admin', 'operator'))
);


-- ============================================================
-- TABLE 2: puvs_tbl
--
-- Purpose:
-- Stores information about registered Public Utility Vehicles.
-- ============================================================

CREATE TABLE puvs_tbl (
    puv_id SERIAL PRIMARY KEY,
    plate_number VARCHAR(20) NOT NULL UNIQUE,
    puv_type VARCHAR(50) NOT NULL,
    capacity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_puv_capacity
        CHECK (capacity > 0)
);


-- ============================================================
-- TABLE 3: counting_records_tbl
--
-- Purpose:
-- Stores every image processed by the YOLO model and the
-- resulting number of detected passengers.
-- ============================================================

CREATE TABLE counting_records_tbl (
    count_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    puv_id INTEGER,
    image_path VARCHAR(255) NOT NULL,
    passenger_count INTEGER NOT NULL DEFAULT 0,
    confidence_threshold DECIMAL(5,4)
        NOT NULL DEFAULT 0.5000,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    
	-- Foreign key to users_tbl
    CONSTRAINT fk_count_user
        FOREIGN KEY (user_id)
        REFERENCES users_tbl(user_id)
        ON DELETE RESTRICT,

    -- Foreign key to puvs_tbl
    CONSTRAINT fk_count_puv
        FOREIGN KEY (puv_id)
        REFERENCES puvs_tbl(puv_id)
        ON DELETE SET NULL,

    -- Passenger count cannot be negative
    CONSTRAINT chk_passenger_count
        CHECK (passenger_count >= 0),

    -- YOLO confidence threshold must be between 0 and 1
    CONSTRAINT chk_confidence_threshold
        CHECK (
            confidence_threshold >= 0
            AND confidence_threshold <= 1
        ),

    -- Valid image-processing statuses
    CONSTRAINT chk_count_status
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed'
            )
        )
);


-- ============================================================
-- TABLE 4: detection_tbl
--
-- Purpose:
-- Stores each individual passenger detected by YOLO in a
-- processed image.
-- ============================================================

CREATE TABLE detection_tbl (
    detection_id SERIAL PRIMARY KEY,
    count_id INTEGER NOT NULL,
    object_class VARCHAR(50)
        NOT NULL DEFAULT 'person',
    confidence DECIMAL(5,4) NOT NULL,
    -- YOLO bounding-box coordinates
    x1 DECIMAL(10,2) NOT NULL,
    y1 DECIMAL(10,2) NOT NULL,
    x2 DECIMAL(10,2) NOT NULL,
    y2 DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Each detection belongs to one counting record
    CONSTRAINT fk_detection_count
        FOREIGN KEY (count_id)
        REFERENCES counting_records_tbl(count_id)
        ON DELETE CASCADE,
    -- Detection confidence must be between 0 and 1
    CONSTRAINT chk_detection_confidence
        CHECK (
            confidence >= 0
            AND confidence <= 1
        )
);
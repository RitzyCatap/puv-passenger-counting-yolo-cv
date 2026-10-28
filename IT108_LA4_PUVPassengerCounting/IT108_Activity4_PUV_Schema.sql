-- IT 108 Activity 4
-- Public Utility Vehicle Passenger Counting Using YOLO-Based Computer Vision

CREATE SCHEMA IF NOT EXISTS passenger_counting;

-- 1. USERS TABLE
CREATE TABLE passenger_counting.users_tbl (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL
);

-- 2. PUV TABLE
CREATE TABLE passenger_counting.puvs_tbl (
    puv_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plate_number TEXT NOT NULL UNIQUE,
    puv_type TEXT NOT NULL
);

-- 3. COUNTING RECORDS TABLE
CREATE TABLE passenger_counting.counting_records_tbl (
    count_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    puv_id BIGINT NOT NULL,
    image_path TEXT NOT NULL,
    passenger_count INTEGER NOT NULL,
    status TEXT NOT NULL,
    processed_at TIMESTAMPTZ,

    CONSTRAINT fk_counting_user
        FOREIGN KEY (user_id)
        REFERENCES passenger_counting.users_tbl(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_counting_puv
        FOREIGN KEY (puv_id)
        REFERENCES passenger_counting.puvs_tbl(puv_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_counting_status
        CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

    CONSTRAINT chk_passenger_count
        CHECK (passenger_count >= 0)
);

-- 4. YOLO DETECTION TABLE
CREATE TABLE passenger_counting.detection_tbl (
    detection_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    count_id BIGINT NOT NULL,
    object_class TEXT NOT NULL,
    confidence NUMERIC(5,4) NOT NULL,
    x1 NUMERIC(10,4) NOT NULL,
    y1 NUMERIC(10,4) NOT NULL,
    x2 NUMERIC(10,4) NOT NULL,
    y2 NUMERIC(10,4) NOT NULL,

    CONSTRAINT fk_detection_count
        FOREIGN KEY (count_id)
        REFERENCES passenger_counting.counting_records_tbl(count_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_detection_confidence
        CHECK (confidence >= 0 AND confidence <= 1)
);
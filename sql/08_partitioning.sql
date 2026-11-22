
-- ============================================================
-- PHASE 5: PARTITIONING STRATEGY
-- Project: LinkedIn Professional Network Database
-- Database: linkedin_large
--
-- Strategy:
--   RANGE partitioning on applications.applied_at
--   Monthly partitions
--
-- Original applications table remains unchanged.
-- ============================================================

SET search_path TO linkedin;

-- ============================================================
-- 1. CREATE PARTITIONED APPLICATIONS TABLE
-- ============================================================

CREATE TABLE linkedin.applications_partitioned (
    application_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status TEXT NOT NULL CHECK (
        status IN (
            'APPLIED', 'HIRED', 'INTERVIEW', 'OFFER',
            'REJECTED', 'SHORTLISTED', 'VIEWED', 'WITHDRAWN'
        )
    ),
    status_updated_at TIMESTAMPTZ NOT NULL,

    -- Partition key must be part of the primary key.
    CONSTRAINT applications_partitioned_pkey
        PRIMARY KEY (application_id, applied_at),

    CONSTRAINT fk_applications_partitioned_job
        FOREIGN KEY (job_id)
        REFERENCES linkedin.jobs(job_id),

    CONSTRAINT fk_applications_partitioned_member
        FOREIGN KEY (member_id)
        REFERENCES linkedin.members(member_id),

    -- Partition-compatible uniqueness constraint.
    CONSTRAINT applications_partitioned_job_member_date_unique
        UNIQUE (job_id, member_id, applied_at)

) PARTITION BY RANGE (applied_at);


-- ============================================================
-- 2. CREATE MONTHLY PARTITIONS
--    Automatically derive the date range from existing data.
-- ============================================================

DO $$
DECLARE
    min_month DATE;
    max_month DATE;
    partition_month DATE;
    partition_name TEXT;
    lower_bound TIMESTAMPTZ;
    upper_bound TIMESTAMPTZ;
BEGIN

    SELECT
        date_trunc('month', MIN(applied_at))::DATE,
        date_trunc('month', MAX(applied_at))::DATE
    INTO min_month, max_month
    FROM linkedin.applications;

    -- Fallback when the source table is empty.
    IF min_month IS NULL THEN
        min_month :=
            date_trunc('month', CURRENT_DATE)::DATE - INTERVAL '12 months';
        max_month :=
            date_trunc('month', CURRENT_DATE)::DATE + INTERVAL '12 months';
    END IF;

    partition_month := min_month;

    WHILE partition_month <= max_month LOOP

        partition_name :=
            'applications_p' || to_char(partition_month, 'YYYY_MM');

        lower_bound := partition_month::TIMESTAMP AT TIME ZONE 'UTC';
        upper_bound :=
            (partition_month + INTERVAL '1 month')::TIMESTAMP
            AT TIME ZONE 'UTC';

        EXECUTE format(
            'CREATE TABLE linkedin.%I
             PARTITION OF linkedin.applications_partitioned
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            lower_bound,
            upper_bound
        );

        partition_month :=
            (partition_month + INTERVAL '1 month')::DATE;

    END LOOP;

END $$;


-- ============================================================
-- 3. DEFAULT PARTITION
--    Catches dates outside the generated monthly range.
-- ============================================================

CREATE TABLE linkedin.applications_p_default
PARTITION OF linkedin.applications_partitioned
DEFAULT;


-- ============================================================
-- 4. INDEXES ON THE PARTITIONED TABLE
--    PostgreSQL creates corresponding partition indexes.
-- ============================================================

CREATE INDEX idx_applications_part_member_date
ON linkedin.applications_partitioned
(member_id, applied_at DESC)
INCLUDE (application_id, job_id, status);

CREATE INDEX idx_applications_part_job_date
ON linkedin.applications_partitioned
(job_id, applied_at);

CREATE INDEX idx_applications_part_date
ON linkedin.applications_partitioned
(applied_at DESC);


-- ============================================================
-- 5. PRESERVE GLOBAL (job_id, member_id) UNIQUENESS
--
-- PostgreSQL cannot enforce UNIQUE(job_id, member_id)
-- globally on a table partitioned by applied_at.
--
-- This registry provides a non-partitioned uniqueness
-- constraint and references the partitioned application.
-- ============================================================

CREATE TABLE linkedin.application_uniqueness_registry (
    job_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    application_id INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (job_id, member_id),

    UNIQUE (application_id, applied_at),

    CONSTRAINT fk_registry_job
        FOREIGN KEY (job_id)
        REFERENCES linkedin.jobs(job_id),

    CONSTRAINT fk_registry_member
        FOREIGN KEY (member_id)
        REFERENCES linkedin.members(member_id),

    CONSTRAINT fk_registry_application
        FOREIGN KEY (application_id, applied_at)
        REFERENCES linkedin.applications_partitioned
            (application_id, applied_at)
);


-- ============================================================
-- 6. OPTIONAL DATA MIGRATION
--
-- Uncomment these statements only when you intentionally
-- want to copy all source applications into the new design.
--
-- Run both INSERT statements in the same transaction.
-- The original applications table is not modified.
-- ============================================================

-- BEGIN;

-- INSERT INTO linkedin.applications_partitioned (
--     application_id,
--     job_id,
--     member_id,
--     applied_at,
--     easy_apply,
--     status,
--     status_updated_at
-- )
-- SELECT
--     application_id,
--     job_id,
--     member_id,
--     applied_at,
--     easy_apply,
--     status,
--     status_updated_at
-- FROM linkedin.applications;

-- INSERT INTO linkedin.application_uniqueness_registry (
--     job_id,
--     member_id,
--     application_id,
--     applied_at
-- )
-- SELECT
--     job_id,
--     member_id,
--     application_id,
--     applied_at
-- FROM linkedin.applications;

-- COMMIT;


-- ============================================================
-- 7. PARTITION PRUNING TEST
-- ============================================================

-- Inspect available partitions first.
SELECT
    parent.relname AS parent_table,
    child.relname AS partition_name
FROM pg_inherits
JOIN pg_class parent
    ON pg_inherits.inhparent = parent.oid
JOIN pg_class child
    ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'applications_partitioned'
ORDER BY child.relname;


-- Query with a date filter.
-- Replace the date range with dates covered by your partitions.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    application_id,
    job_id,
    member_id,
    applied_at,
    status
FROM linkedin.applications_partitioned
WHERE applied_at >= TIMESTAMPTZ '2026-01-01 00:00:00+00'
  AND applied_at <  TIMESTAMPTZ '2026-02-01 00:00:00+00';


-- ============================================================
-- 8. VERIFY PARTITION COUNTS
-- ============================================================

SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS row_count
FROM linkedin.applications_partitioned
GROUP BY tableoid
ORDER BY partition_name;


-- ============================================================
-- 9. ANALYZE PARTITIONED TABLE
-- ============================================================

ANALYZE linkedin.applications_partitioned;

-- ============================================================
-- END OF PARTITIONING SCRIPT
-- ============================================================

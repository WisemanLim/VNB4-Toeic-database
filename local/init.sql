-- Local Postgres bootstrap: extensions + roles.
-- Runs once via docker-entrypoint-initdb.d.

CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- read-only role for analytics / Grafana
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'toeic_ro') THEN
    CREATE ROLE toeic_ro LOGIN PASSWORD 'toeic_ro';
  END IF;
END $$;
GRANT CONNECT ON DATABASE toeic_local TO toeic_ro;

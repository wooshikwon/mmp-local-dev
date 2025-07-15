-- PostgreSQL 데이터베이스 초기화 스크립트
-- ML Pipeline Local Development Environment

-- Create features schema for Feature Store
CREATE SCHEMA IF NOT EXISTS features;

-- Grant permissions to mluser
GRANT ALL PRIVILEGES ON SCHEMA features TO mluser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA features TO mluser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA features TO mluser;

-- Create extension for better performance
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set default schema search path
ALTER USER mluser SET search_path TO features, public;

-- Create indexes for better performance
-- (Will be created after tables are created in seed-features.sql)

-- Log successful initialization
DO $$
BEGIN
  RAISE NOTICE 'Database initialization completed successfully';
  RAISE NOTICE 'Created schema: features';
  RAISE NOTICE 'Granted permissions to user: mluser';
END $$; 
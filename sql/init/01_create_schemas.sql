-- ML Pipeline Local Database 초기화
-- Blueprint v17.0: "완전한 실험실" 철학 구현

-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS feature_mart;
CREATE SCHEMA IF NOT EXISTS spine_data;
CREATE SCHEMA IF NOT EXISTS raw_data;

-- 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA feature_mart TO mluser;
GRANT ALL PRIVILEGES ON SCHEMA spine_data TO mluser;
GRANT ALL PRIVILEGES ON SCHEMA raw_data TO mluser;

-- MLflow Backend Store 권한 (MLflow가 자동으로 테이블 생성)
GRANT ALL PRIVILEGES ON SCHEMA public TO mluser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO mluser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO mluser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO mluser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO mluser;

-- Extensions 설치
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- 로그 테이블 생성
CREATE TABLE IF NOT EXISTS public.ml_pipeline_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    level VARCHAR(20),
    message TEXT,
    component VARCHAR(100),
    context JSONB
);

COMMENT ON TABLE public.ml_pipeline_logs IS 'ML Pipeline 시스템 로그';

-- MLflow는 서버 시작시 자동으로 테이블을 생성합니다
-- (experiments, runs, tags, metrics, params, artifacts 등) 
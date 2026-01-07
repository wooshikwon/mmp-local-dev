#!/bin/bash
# Fraud Detection 데이터 PostgreSQL 로드 스크립트
# mmp-local-dev 환경용

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data/processed"
SQL_DIR="${SCRIPT_DIR}"

# 환경 변수 로드
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
fi

# 기본값 설정
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-mlpipeline}"
POSTGRES_USER="${POSTGRES_USER:-mluser}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-mlpassword}"

echo "=============================================="
echo "Fraud Detection 데이터 로드 시작"
echo "=============================================="
echo "Host: ${POSTGRES_HOST}:${POSTGRES_PORT}"
echo "Database: ${POSTGRES_DB}"
echo "User: ${POSTGRES_USER}"
echo ""

# PostgreSQL 연결 확인
echo "PostgreSQL 연결 확인..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT 1;" > /dev/null 2>&1 || {
    echo "Error: PostgreSQL 연결 실패"
    echo "Docker Compose가 실행 중인지 확인하세요: docker-compose up -d"
    exit 1
}
echo "연결 성공!"
echo ""

# 테이블 생성
echo "테이블 생성 중..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f "${DATA_DIR}/create_tables.sql"
echo ""

# CSV 데이터 로드
echo "CSV 데이터 로드 중..."

# transactions 테이블
echo "  - transactions 로드..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\COPY features.transactions(transaction_id, user_id, merchant_id, category, amount, is_fraud, event_timestamp, lat, long, merch_lat, merch_long) FROM '${DATA_DIR}/transactions.csv' WITH CSV HEADER;"

# user_demographics 테이블
echo "  - user_demographics 로드..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\COPY features.user_demographics(user_id, gender, city, state, zip_code, lat, long, city_pop, job, dob, age, created_at) FROM '${DATA_DIR}/user_demographics.csv' WITH CSV HEADER;"

# user_features 테이블
echo "  - user_features 로드..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\COPY features.user_features(user_id, total_transactions, total_amount, avg_amount, max_amount, min_amount, std_amount, transactions_7d, amount_7d, avg_amount_7d, transactions_30d, amount_30d, avg_amount_30d, unique_merchants, unique_categories, fraud_count, created_at) FROM '${DATA_DIR}/user_features.csv' WITH CSV HEADER;"

# merchant_features 테이블
echo "  - merchant_features 로드..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\COPY features.merchant_features(merchant_id, avg_transaction_amount, std_transaction_amount, min_transaction_amount, max_transaction_amount, total_transactions, fraud_count, fraud_rate, primary_category, lat, long, created_at) FROM '${DATA_DIR}/merchant_features.csv' WITH CSV HEADER;"

# category_features 테이블
echo "  - category_features 로드..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\COPY features.category_features(category, avg_amount, std_amount, min_amount, max_amount, total_transactions, fraud_count, fraud_rate, created_at) FROM '${DATA_DIR}/category_features.csv' WITH CSV HEADER;"

echo ""

# 통계 업데이트
echo "테이블 통계 업데이트..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" << EOF
ANALYZE features.transactions;
ANALYZE features.user_demographics;
ANALYZE features.user_features;
ANALYZE features.merchant_features;
ANALYZE features.category_features;
EOF

# 로드 결과 확인
echo ""
echo "=============================================="
echo "로드 결과"
echo "=============================================="
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" << EOF
SELECT 'transactions' as table_name, COUNT(*) as row_count FROM features.transactions
UNION ALL
SELECT 'user_demographics', COUNT(*) FROM features.user_demographics
UNION ALL
SELECT 'user_features', COUNT(*) FROM features.user_features
UNION ALL
SELECT 'merchant_features', COUNT(*) FROM features.merchant_features
UNION ALL
SELECT 'category_features', COUNT(*) FROM features.category_features
ORDER BY table_name;
EOF

echo ""
echo "=============================================="
echo "데이터 로드 완료!"
echo "=============================================="

#!/bin/bash
# Fraud Detection 환경 전체 셋업 스크립트
# mmp-local-dev + Feast Feature Store

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "=============================================="
echo "Fraud Detection 개발 환경 셋업"
echo "=============================================="
echo ""

# 환경 변수 로드
if [ -f ".env" ]; then
    source ".env"
else
    echo "Warning: .env 파일이 없습니다. .env.example을 복사하세요."
    echo "cp .env.example .env"
fi

# Step 1: Docker Compose 시작
echo "[Step 1/5] Docker Compose 시작..."
docker-compose up -d
echo "Docker 서비스 시작 대기 (15초)..."
sleep 15

# Step 2: 데이터 전처리
echo ""
echo "[Step 2/5] Kaggle 데이터 전처리..."
if [ ! -f "data/fraudTrain.csv" ]; then
    echo "Error: Kaggle 데이터가 없습니다."
    echo "먼저 다음 명령을 실행하세요:"
    echo "  kaggle datasets download -d kartik2112/fraud-detection -p data --unzip"
    exit 1
fi
python3 scripts/prepare_fraud_data.py

# Step 3: 데이터 로드
echo ""
echo "[Step 3/5] PostgreSQL 데이터 로드..."
bash scripts/load_fraud_data.sh

# Step 4: Feast 적용
echo ""
echo "[Step 4/5] Feast Feature Store 적용..."
cd feast

# Feast가 설치되어 있는지 확인
if ! command -v feast &> /dev/null; then
    echo "Feast 설치 중..."
    pip install feast[postgres] -q
fi

feast apply
cd ..

# Step 5: 검증
echo ""
echo "[Step 5/5] 셋업 검증..."

# PostgreSQL 테이블 확인
echo ""
echo "=== PostgreSQL 테이블 현황 ==="
PGPASSWORD="${POSTGRES_PASSWORD:-mlpassword}" psql \
    -h "${POSTGRES_HOST:-localhost}" \
    -p "${POSTGRES_PORT:-5432}" \
    -U "${POSTGRES_USER:-mluser}" \
    -d "${POSTGRES_DB:-mlpipeline}" \
    -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'features' ORDER BY tablename;"

# Feast Feature View 확인
echo ""
echo "=== Feast Feature Views ==="
cd feast && feast feature-views list && cd ..

echo ""
echo "=============================================="
echo "셋업 완료!"
echo "=============================================="
echo ""
echo "다음 명령으로 Point-in-Time Join 테스트:"
echo "  python3 scripts/test_point_in_time_join.py"
echo ""
echo "서비스 상태 확인:"
echo "  docker-compose ps"
echo ""
echo "서비스 중지:"
echo "  docker-compose down"

#!/bin/bash

# 🚀 MMP Local Dev Environment - One-Stop Setup
# Blueprint v17.0: 완전한 개발 환경 자동 구성

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🚀 MMP Local Dev Environment - One-Stop Setup"
    echo "Blueprint v17.0: PostgreSQL + Redis + MLflow + Feature Store"
    echo "=================================================================="
    echo -e "${NC}"
}

check_dependencies() {
    log_step "의존성 확인 중..."
    
    # Docker 확인
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다!"
        log_info "Docker Desktop 또는 OrbStack을 설치하세요:"
        log_info "- Docker Desktop: https://docs.docker.com/desktop/install/mac-install/"
        log_info "- OrbStack: https://orbstack.dev/ (추천)"
        exit 1
    fi
    
    # Docker Compose 확인
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다!"
        exit 1
    fi
    
    # Docker 데몬 확인
    if ! docker info &> /dev/null; then
        log_error "Docker 데몬이 실행되지 않았습니다!"
        log_info "Docker Desktop 또는 OrbStack을 실행하세요"
        exit 1
    fi
    
    log_success "모든 의존성 확인 완료"
}

setup_environment() {
    log_step "환경 설정 중..."
    
    # 환경 변수 파일 생성
    if [ ! -f ".env" ]; then
        log_info ".env 파일 생성 중..."
        cat > .env << EOF
# PostgreSQL 설정
POSTGRES_DB=mlpipeline
POSTGRES_USER=mluser
POSTGRES_PASSWORD=mlpassword
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Redis 설정
REDIS_HOST=localhost
REDIS_PORT=6379

# MLflow 설정
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_S3_ENDPOINT_URL=http://localhost:9000

# Feature Store 설정
FEATURE_STORE_OFFLINE_URI=postgresql://mluser:mlpassword@localhost:5432/mlpipeline
FEATURE_STORE_ONLINE_URI=redis://localhost:6379
EOF
        log_success ".env 파일 생성 완료"
    fi
}

start_services() {
    log_step "서비스 시작 중..."
    
    # 기존 컨테이너 정리
    docker-compose down -v 2>/dev/null || true
    
    # 서비스 시작
    log_info "PostgreSQL + Redis 시작 중..."
    docker-compose up -d
    
    # 서비스 health check
    log_info "서비스 준비 상태 확인 중..."
    
    # PostgreSQL 대기
    log_info "PostgreSQL 준비 대기 중..."
    timeout=90
    count=0
    while [ $count -lt $timeout ]; do
        # pg_isready 대신 실제 쿼리 실행으로 더 안정적인 확인
        if docker-compose exec -T postgresql psql -U mluser -d mlpipeline -c "SELECT 1" &>/dev/null; then
            log_success "PostgreSQL 준비 완료 (쿼리 응답 확인)"
            break
        fi
        sleep 2
        count=$((count + 2))
    done
    
    if [ $count -ge $timeout ]; then
        log_error "PostgreSQL 시작 타임아웃"
        docker-compose logs postgresql
        exit 1
    fi
    
    # Redis 대기
    log_info "Redis 준비 대기 중..."
    timeout=60
    count=0
    while [ $count -lt $timeout ]; do
        if docker-compose exec -T redis redis-cli ping &>/dev/null; then
            log_success "Redis 준비 완료"
            break
        fi
        sleep 1
        count=$((count + 1))
    done
    
    if [ $count -eq $timeout ]; then
        log_error "Redis 시작 타임아웃"
        exit 1
    fi
    
    log_success "모든 서비스 준비 완료"
}

initialize_database() {
    log_step "데이터베이스 초기화 중..."
    
    # Feature Store 스키마 생성
    docker-compose exec -T postgresql psql -U mluser -d mlpipeline << EOF
-- Feature Store 스키마 생성
CREATE SCHEMA IF NOT EXISTS feature_store;

-- 샘플 피처 테이블 생성
CREATE TABLE IF NOT EXISTS feature_store.user_demographics (
    user_id VARCHAR(100) PRIMARY KEY,
    age INTEGER,
    gender VARCHAR(10),
    education_level VARCHAR(50),
    income_bracket VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS feature_store.user_behavior (
    user_id VARCHAR(100) PRIMARY KEY,
    click_through_rate DECIMAL(5,4),
    session_frequency INTEGER,
    avg_session_duration DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS feature_store.purchase_history (
    user_id VARCHAR(100) PRIMARY KEY,
    total_orders INTEGER,
    avg_order_value DECIMAL(10,2),
    preferred_category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 샘플 데이터 삽입
INSERT INTO feature_store.user_demographics (user_id, age, gender, education_level, income_bracket) 
VALUES 
    ('test_user_123', 28, 'M', 'Bachelor', '50K-75K'),
    ('test_user_456', 35, 'F', 'Master', '75K-100K'),
    ('test_user_789', 42, 'M', 'PhD', '100K+')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO feature_store.user_behavior (user_id, click_through_rate, session_frequency, avg_session_duration)
VALUES 
    ('test_user_123', 0.0523, 12, 245.67),
    ('test_user_456', 0.0789, 8, 189.34),
    ('test_user_789', 0.0456, 15, 312.89)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO feature_store.purchase_history (user_id, total_orders, avg_order_value, preferred_category)
VALUES 
    ('test_user_123', 23, 87.50, 'Electronics'),
    ('test_user_456', 15, 156.75, 'Fashion'),
    ('test_user_789', 31, 203.25, 'Books')
ON CONFLICT (user_id) DO NOTHING;
EOF
    
    log_success "데이터베이스 초기화 완료"
}

setup_redis_features() {
    log_step "Redis 피처 데이터 설정 중..."
    
    # Redis에 샘플 피처 데이터 저장
    docker-compose exec -T redis redis-cli << EOF
SET "user_demographics:age:test_user_123" "28"
SET "user_demographics:gender:test_user_123" "M"
SET "user_demographics:education_level:test_user_123" "Bachelor"
SET "user_demographics:income_bracket:test_user_123" "50K-75K"

SET "user_behavior:click_through_rate:test_user_123" "0.0523"
SET "user_behavior:session_frequency:test_user_123" "12"
SET "user_behavior:avg_session_duration:test_user_123" "245.67"

SET "purchase_history:total_orders:test_user_123" "23"
SET "purchase_history:avg_order_value:test_user_123" "87.50"
SET "purchase_history:preferred_category:test_user_123" "Electronics"
EOF
    
    log_success "Redis 피처 데이터 설정 완료"
}

initialize_feast() {
    log_step "Feast Feature Store 초기화 중..."
    
    # Feast 디렉토리 존재 확인
    if [ ! -d "feast" ]; then
        log_warn "Feast 디렉토리가 없어 초기화를 건너뜁니다."
        return
    fi
    
    # 가상환경 활성화 및 feast apply 실행
    log_info "Feast 레지스트리 적용 중..."
    (
        source .venv/bin/activate && \
        cd feast && \
        feast apply
    )
    
    log_success "Feast Feature Store 초기화 완료"
}

print_usage_guide() {
    echo ""
    echo -e "${GREEN}=================================================================="
    echo "🎉 MMP Local Dev Environment 설정 완료!"
    echo "=================================================================="
    echo -e "${NC}"
    
    echo "📱 서비스 접속 정보:"
    echo "   🗄️  PostgreSQL:         localhost:5432"
    echo "   🔴 Redis:              localhost:6379"
    echo "   📊 MLflow:             http://localhost:5000 (ML Pipeline 실행 후)"
    echo ""
    
    echo "🔗 연결 테스트:"
    echo "   # PostgreSQL 연결"
    echo "   docker-compose exec postgresql psql -U mluser -d mlpipeline"
    echo ""
    echo "   # Redis 연결"
    echo "   docker-compose exec redis redis-cli"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "   # ML Pipeline 디렉토리로 이동"
    echo "   cd ../modern-ml-pipeline"
    echo ""
    echo "   # DEV 환경에서 학습 실행"
    echo "   APP_ENV=dev uv run python main.py train --recipe-file dev_classification_test"
    echo ""
    echo "   # API 서빙 실행"
    echo "   APP_ENV=dev uv run python main.py serve-api --run-id latest"
    echo ""
    
    echo "🛠️ 환경 관리:"
    echo "   # 환경 중지"
    echo "   docker-compose down"
    echo ""
    echo "   # 환경 완전 삭제"
    echo "   docker-compose down -v"
    echo ""
    echo "   # 환경 재시작"
    echo "   ./setup.sh"
    echo ""
}

# 상태 확인 함수
check_status() {
    echo -e "${BLUE}[STATUS]${NC} 서비스 상태 확인"
    
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✅ 서비스 실행 중${NC}"
        docker-compose ps
    else
        echo -e "${RED}❌ 서비스가 실행되지 않음${NC}"
        echo "다시 실행하려면: ./setup.sh"
    fi
}

# 메인 실행
main() {
    print_banner
    check_dependencies
    setup_environment
    start_services
    initialize_database
    setup_redis_features
    initialize_feast
    print_usage_guide
    
    log_success "모든 설정이 완료되었습니다! 🚀"
}

# 옵션 처리
case "${1:-}" in
    --status)
        check_status
        exit 0
        ;;
    --stop)
        log_info "서비스 중지 중..."
        docker-compose down
        log_success "서비스 중지 완료"
        exit 0
        ;;
    --clean)
        log_info "서비스 완전 삭제 중..."
        docker-compose down -v
        log_success "서비스 완전 삭제 완료"
        exit 0
        ;;
    --help)
        echo "MMP Local Dev Environment Setup"
        echo ""
        echo "사용법: $0 [옵션]"
        echo ""
        echo "옵션:"
        echo "  (없음)        전체 환경 설정 실행"
        echo "  --status      현재 상태 확인"
        echo "  --stop        서비스 중지"
        echo "  --clean       서비스 완전 삭제"
        echo "  --help        도움말 표시"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "알 수 없는 옵션: $1"
        echo "도움말: $0 --help"
        exit 1
        ;;
esac
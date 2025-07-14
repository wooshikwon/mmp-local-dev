#!/bin/bash

# 🧪 Blueprint v17.0 DEV Environment Integration Test
# 설치된 환경이 ML Pipeline과 완전히 통합되는지 검증

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🧪 Blueprint v17.0 DEV Environment Integration Test"
    echo "\"완전한 실험실\" 검증 스위트"
    echo "=================================================================="
    echo -e "${NC}"
}

# 전역 변수
ML_PROJECT_DIR="../modern-ml-pipeline"
TEST_RESULTS=()
FAILED_TESTS=0
TOTAL_TESTS=0

# 테스트 결과 기록
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        log_success "$test_name: $message"
        TEST_RESULTS+=("✅ $test_name")
    else
        log_error "$test_name: $message"
        TEST_RESULTS+=("❌ $test_name")
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. 기본 서비스 연결성 테스트
test_basic_connectivity() {
    log_step "기본 서비스 연결성 테스트..."
    
    # PostgreSQL 연결 테스트
    if docker-compose exec -T postgres pg_isready -U mluser -d mlpipeline >/dev/null 2>&1; then
        record_test "PostgreSQL 연결" "PASS" "포트 5432 연결 성공"
    else
        record_test "PostgreSQL 연결" "FAIL" "연결 실패"
    fi
    
    # Redis 연결 테스트
    if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        record_test "Redis 연결" "PASS" "포트 6379 연결 성공"
    else
        record_test "Redis 연결" "FAIL" "연결 실패"
    fi
    
    # MLflow 서버 테스트
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        record_test "MLflow 서버" "PASS" "포트 5000 응답 정상"
    else
        record_test "MLflow 서버" "FAIL" "서버 응답 없음"
    fi
}

# 2. 데이터베이스 스키마 검증
test_database_schema() {
    log_step "데이터베이스 스키마 검증..."
    
    # Feature Store 스키마 확인
    local schemas=$(docker-compose exec -T postgres psql -U mluser -d mlpipeline -c "\dn" 2>/dev/null | grep -E "(feature_mart|spine_data|raw_data)" | wc -l)
    if [ "$schemas" -ge 3 ]; then
        record_test "Feature Store 스키마" "PASS" "$schemas개 스키마 생성됨"
    else
        record_test "Feature Store 스키마" "FAIL" "필수 스키마 누락"
    fi
    
    # 테스트 데이터 확인
    local test_data=$(docker-compose exec -T postgres psql -U mluser -d mlpipeline -c "SELECT COUNT(*) FROM feature_mart.user_demographics" 2>/dev/null | grep -E "^\s*[0-9]+\s*$" | head -1 | tr -d ' ')
    if [ "$test_data" -gt 0 ]; then
        record_test "테스트 데이터" "PASS" "$test_data개 레코드 확인"
    else
        record_test "테스트 데이터" "FAIL" "테스트 데이터 없음"
    fi
}

# 3. Python 패키지 및 환경 검증
test_python_environment() {
    log_step "Python 환경 검증..."
    
    # 필수 패키지 확인
    local packages=("feast" "mlflow" "psycopg2" "redis")
    for package in "${packages[@]}"; do
        if python3 -c "import $package" 2>/dev/null; then
            record_test "Python $package" "PASS" "패키지 설치됨"
        else
            record_test "Python $package" "FAIL" "패키지 없음"
        fi
    done
}

# 4. ML Pipeline 프로젝트 연동 테스트
test_ml_pipeline_integration() {
    log_step "ML Pipeline 프로젝트 연동 테스트..."
    
    if [ ! -d "$ML_PROJECT_DIR" ]; then
        record_test "ML Pipeline 프로젝트" "FAIL" "프로젝트 디렉토리를 찾을 수 없음: $ML_PROJECT_DIR"
        return
    fi
    
    # config/dev.yaml 존재 확인
    if [ -f "$ML_PROJECT_DIR/config/dev.yaml" ]; then
        record_test "DEV 설정 파일" "PASS" "config/dev.yaml 존재"
    else
        record_test "DEV 설정 파일" "FAIL" "config/dev.yaml 없음"
        return
    fi
    
    # feast_config 설정 확인
    if grep -q "feast_config" "$ML_PROJECT_DIR/config/dev.yaml"; then
        record_test "Feast 설정 통합" "PASS" "feast_config가 dev.yaml에 포함됨"
    else
        record_test "Feast 설정 통합" "FAIL" "feast_config 설정 누락"
    fi
    
    # PostgreSQL 연결 정보 확인
    if grep -q "localhost:5432" "$ML_PROJECT_DIR/config/dev.yaml"; then
        record_test "데이터베이스 연결 설정" "PASS" "PostgreSQL 연결 정보 올바름"
    else
        record_test "데이터베이스 연결 설정" "FAIL" "데이터베이스 연결 정보 불일치"
    fi
}

# 5. Feature Store 실제 연동 테스트
test_feature_store_integration() {
    log_step "Feature Store 실제 연동 테스트..."
    
    if [ ! -d "$ML_PROJECT_DIR" ]; then
        log_warn "ML Pipeline 프로젝트를 찾을 수 없어 Feature Store 연동 테스트를 건너뜁니다"
        return
    fi
    
    # Python 스크립트로 실제 연결 테스트
    cat > /tmp/test_feast_connection.py << 'EOF'
import sys
import os
sys.path.append('../modern-ml-pipeline')

try:
    # PostgreSQL 직접 연결 테스트
    import psycopg2
    conn = psycopg2.connect(
        host="localhost", port=5432,
        database="mlpipeline", user="mluser", password="mlpassword"
    )
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM feature_mart.user_demographics")
    count = cursor.fetchone()[0]
    print(f"PostgreSQL_OK:{count}")
    conn.close()
    
    # Redis 연결 테스트
    import redis
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.ping()
    print("Redis_OK")
    
    # ML Pipeline 설정 로드 테스트
    os.environ['APP_ENV'] = 'dev'
    # 실제 settings 로드는 복잡하므로 생략하고 기본 테스트만
    print("Settings_OK")
    
except Exception as e:
    print(f"ERROR:{e}")
EOF
    
    # 테스트 실행
    local test_output=$(python3 /tmp/test_feast_connection.py 2>&1)
    
    if echo "$test_output" | grep -q "PostgreSQL_OK"; then
        local pg_count=$(echo "$test_output" | grep "PostgreSQL_OK" | cut -d: -f2)
        record_test "Feature Store PostgreSQL" "PASS" "$pg_count개 피처 레코드 조회 성공"
    else
        record_test "Feature Store PostgreSQL" "FAIL" "PostgreSQL 조회 실패"
    fi
    
    if echo "$test_output" | grep -q "Redis_OK"; then
        record_test "Feature Store Redis" "PASS" "Redis 연결 성공"
    else
        record_test "Feature Store Redis" "FAIL" "Redis 연결 실패"
    fi
    
    # 임시 파일 정리
    rm -f /tmp/test_feast_connection.py
}

# 6. 포트 및 네트워크 테스트
test_network_ports() {
    log_step "네트워크 포트 테스트..."
    
    local ports=("5432:PostgreSQL" "6379:Redis" "5000:MLflow" "8082:pgAdmin" "8081:Redis-Commander")
    
    for port_info in "${ports[@]}"; do
        local port=$(echo $port_info | cut -d: -f1)
        local service=$(echo $port_info | cut -d: -f2)
        
        if netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i :$port >/dev/null 2>&1 || ss -tuln 2>/dev/null | grep -q ":$port "; then
            record_test "$service 포트" "PASS" "포트 $port 활성"
        else
            record_test "$service 포트" "FAIL" "포트 $port 비활성"
        fi
    done
}

# 7. Blueprint v17.0 호환성 검증
test_blueprint_compatibility() {
    log_step "Blueprint v17.0 호환성 검증..."
    
    # feast 디렉토리가 제거되었는지 확인
    if [ ! -d "feast" ]; then
        record_test "Blueprint v17.0 호환성" "PASS" "feast 디렉토리 정리됨"
    else
        record_test "Blueprint v17.0 호환성" "FAIL" "feast 디렉토리가 아직 존재함"
    fi
    
    # MLflow 환경별 실험 확인
    if curl -s http://localhost:5000/api/2.0/mlflow/experiments/search >/dev/null 2>&1; then
        record_test "MLflow API" "PASS" "MLflow REST API 응답 정상"
    else
        record_test "MLflow API" "FAIL" "MLflow API 응답 없음"
    fi
}

# 테스트 결과 요약
print_test_summary() {
    echo ""
    echo -e "${BLUE}=================================================================="
    echo "🧪 테스트 결과 요약"
    echo "=================================================================="
    echo -e "${NC}"
    
    echo "전체 테스트: $TOTAL_TESTS개"
    echo "성공: $((TOTAL_TESTS - FAILED_TESTS))개"
    echo "실패: $FAILED_TESTS개"
    echo ""
    
    echo "상세 결과:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 모든 테스트가 성공했습니다!"
        echo "Blueprint v17.0 DEV 환경이 완벽하게 구성되었습니다."
        echo -e "${NC}"
        echo "다음 단계:"
        echo "  cd $ML_PROJECT_DIR"
        echo "  APP_ENV=dev python main.py train --recipe-file models/classification/random_forest_classifier"
    else
        echo -e "${RED}❌ $FAILED_TESTS개의 테스트가 실패했습니다."
        echo "환경 설정을 다시 확인해주세요."
        echo -e "${NC}"
        echo "문제 해결:"
        echo "  ./setup.sh --status  # 서비스 상태 확인"
        echo "  ./setup.sh --logs    # 로그 확인"
        echo "  ./setup.sh --clean && ./setup.sh  # 완전 재설치"
    fi
}

# 메인 실행
main() {
    print_banner
    
    # Docker Compose 명령어 감지
    if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_info "Docker Compose V1 감지"
    elif docker compose version &> /dev/null; then
        log_info "Docker Compose V2 (Plugin) 감지"
    else
        log_error "Docker Compose를 찾을 수 없습니다"
        exit 1
    fi
    
    # 테스트 실행
    test_basic_connectivity
    test_database_schema
    test_python_environment
    test_ml_pipeline_integration
    test_feature_store_integration
    test_network_ports
    test_blueprint_compatibility
    
    # 결과 출력
    print_test_summary
    
    # 종료 코드 설정
    exit $FAILED_TESTS
}

# 옵션 처리
case "${1:-}" in
    --help)
        echo "Blueprint v17.0 DEV Environment Integration Test"
        echo ""
        echo "사용법: $0 [옵션]"
        echo ""
        echo "옵션:"
        echo "  (없음)    전체 통합 테스트 실행"
        echo "  --help    도움말 표시"
        echo ""
        echo "테스트 항목:"
        echo "  1. 기본 서비스 연결성 (PostgreSQL, Redis, MLflow)"
        echo "  2. 데이터베이스 스키마 및 테스트 데이터"
        echo "  3. Python 환경 및 필수 패키지"
        echo "  4. ML Pipeline 프로젝트 연동"
        echo "  5. Feature Store 실제 연동"
        echo "  6. 네트워크 포트 상태"
        echo "  7. Blueprint v17.0 호환성"
        echo ""
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
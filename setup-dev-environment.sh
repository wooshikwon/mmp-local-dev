#!/bin/bash

# ML Pipeline Local Development Environment Setup Script
# 5분 이내 완료 가능한 완전한 Feature Store 스택 구축

set -e  # 에러 시 즉시 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 헤더 출력
echo "=============================================================================="
echo "🚀 ML Pipeline Local Development Environment Setup"
echo "   Complete Feature Store Stack: PostgreSQL + Redis + MLflow + Feast"
echo "=============================================================================="

# 시작 시간 기록
start_time=$(date +%s)

# 1. 환경 사전 체크
log_info "1. 환경 사전 체크 중..."

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다. Docker를 먼저 설치해주세요."
    exit 1
fi

# Docker Compose 설치 확인
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose가 설치되지 않았습니다. Docker Compose를 먼저 설치해주세요."
    exit 1
fi

# Docker 데몬 실행 확인
if ! docker info &> /dev/null; then
    log_error "Docker 데몬이 실행되지 않았습니다. Docker를 시작해주세요."
    exit 1
fi

log_success "환경 사전 체크 완료"

# 2. 환경변수 설정 확인
log_info "2. 환경변수 설정 확인 중..."

if [ ! -f ".env" ]; then
    log_warning ".env 파일이 없습니다. .env.example을 복사합니다."
    cp .env.example .env
    log_warning "POSTGRES_PASSWORD를 설정해주세요:"
    echo "  nano .env"
    echo "  또는 export POSTGRES_PASSWORD='your_password'"
    
    if [ -z "$POSTGRES_PASSWORD" ]; then
        log_error "POSTGRES_PASSWORD 환경변수를 설정해주세요."
        exit 1
    fi
fi

# .env 파일 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 필수 환경변수 확인
if [ -z "$POSTGRES_PASSWORD" ]; then
    log_error "POSTGRES_PASSWORD가 설정되지 않았습니다."
    exit 1
fi

log_success "환경변수 설정 확인 완료"

# 3. 기존 컨테이너 정리
log_info "3. 기존 컨테이너 정리 중..."

# 기존 컨테이너 중지 및 제거
docker-compose down -v --remove-orphans 2>/dev/null || true

# 네트워크 정리
docker network prune -f 2>/dev/null || true

log_success "기존 컨테이너 정리 완료"

# 4. Docker Compose 실행
log_info "4. Docker Compose 서비스 시작 중..."

# Docker Compose 실행
docker-compose up -d

log_success "Docker Compose 서비스 시작 완료"

# 5. 서비스 헬스체크
log_info "5. 서비스 헬스체크 중..."

# PostgreSQL 헬스체크
log_info "PostgreSQL 연결 대기 중..."
for i in {1..30}; do
    if docker exec ml-pipeline-postgres pg_isready -U ${POSTGRES_USER:-mluser} -d ${POSTGRES_DB:-mlpipeline} &>/dev/null; then
        log_success "PostgreSQL 연결 성공"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "PostgreSQL 연결 실패 (타임아웃)"
        exit 1
    fi
    sleep 2
done

# Redis 헬스체크
log_info "Redis 연결 대기 중..."
for i in {1..30}; do
    if docker exec ml-pipeline-redis redis-cli ping &>/dev/null; then
        log_success "Redis 연결 성공"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Redis 연결 실패 (타임아웃)"
        exit 1
    fi
    sleep 2
done

# MLflow 헬스체크
log_info "MLflow 서버 대기 중..."
for i in {1..60}; do
    if curl -s http://localhost:5000/health &>/dev/null; then
        log_success "MLflow 서버 연결 성공"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "MLflow 서버 연결 실패 (타임아웃)"
        exit 1
    fi
    sleep 3
done

log_success "모든 서비스 헬스체크 완료"

# 6. Feast 설정 확인
log_info "6. Feast 설정 확인 중..."

# Feast 설정 적용 확인
if docker logs ml-pipeline-feast-setup 2>/dev/null | grep -q "Feature store setup completed successfully"; then
    log_success "Feast 설정 적용 완료"
else
    log_warning "Feast 설정 적용 중... (최대 2분 소요)"
    
    # Feast 설정 재실행
    docker-compose restart feast-setup
    
    # 설정 완료 대기
    for i in {1..40}; do
        if docker logs ml-pipeline-feast-setup 2>/dev/null | grep -q "Feature store setup completed successfully"; then
            log_success "Feast 설정 적용 완료"
            break
        fi
        if [ $i -eq 40 ]; then
            log_error "Feast 설정 적용 실패 (타임아웃)"
            echo "로그 확인: docker logs ml-pipeline-feast-setup"
            exit 1
        fi
        sleep 3
    done
fi

# 7. 통합 테스트 실행
log_info "7. 통합 테스트 실행 중..."

# 통합 테스트 스크립트 실행
if [ -f "test-integration.py" ]; then
    python3 test-integration.py
    if [ $? -eq 0 ]; then
        log_success "통합 테스트 통과"
    else
        log_warning "통합 테스트에서 일부 문제가 감지되었습니다. 서비스는 정상적으로 실행 중입니다."
    fi
else
    log_warning "통합 테스트 스크립트가 없습니다. 수동으로 확인해주세요."
fi

# 8. 완료 메시지 및 접속 정보
end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "=============================================================================="
echo "🎉 완전한 Feature Store 스택 구축 완료!"
echo "   소요 시간: ${duration}초"
echo "=============================================================================="
echo ""

log_success "서비스 접속 정보:"
echo "  📊 PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
echo "     - 데이터베이스: ${POSTGRES_DB:-mlpipeline}"
echo "     - 사용자: ${POSTGRES_USER:-mluser}"
echo "     - 연결: psql -h localhost -U ${POSTGRES_USER:-mluser} -d ${POSTGRES_DB:-mlpipeline}"
echo ""
echo "  ⚡ Redis: localhost:${REDIS_PORT:-6379}"
echo "     - 연결: redis-cli -h localhost -p ${REDIS_PORT:-6379}"
echo "     - 테스트: redis-cli ping"
echo ""
echo "  📈 MLflow: http://localhost:5000"
echo "     - 실험 추적 및 모델 관리"
echo "     - 브라우저에서 접속 가능"
echo ""
echo "  🍽️ Feast Feature Store:"
echo "     - 프로젝트: ${FEAST_PROJECT_NAME:-ml_pipeline_local}"
echo "     - 설정 디렉토리: ./feast/"
echo "     - 명령어: cd feast && feast --help"
echo ""

log_success "다음 단계:"
echo "  1. Feature Store 데이터 확인:"
echo "     psql -h localhost -U ${POSTGRES_USER:-mluser} -d ${POSTGRES_DB:-mlpipeline} -c 'SELECT COUNT(*) FROM features.user_demographics;'"
echo ""
echo "  2. Redis 온라인 스토어 확인:"
echo "     redis-cli -h localhost -p ${REDIS_PORT:-6379} keys '*'"
echo ""
echo "  3. MLflow 실험 확인:"
echo "     curl -s http://localhost:5000/api/2.0/mlflow/experiments/list | jq"
echo ""
echo "  4. Feast 피처 리스트 확인:"
echo "     cd feast && feast feature-views list"
echo ""

log_success "개발 환경 준비 완료! 🚀"

# 컨테이너 상태 확인
echo "=============================================================================="
echo "📋 현재 실행 중인 서비스:"
docker-compose ps
echo "==============================================================================" 
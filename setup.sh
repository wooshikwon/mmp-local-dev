#!/bin/bash

# 🏗️ ML Pipeline Local Database Environment Setup
# Blueprint v17.0: "완전한 실험실" 철학 구현
# PostgreSQL + Redis + MLflow + Feast 완전 자동화 설치
# 완전히 새로운 컴퓨터에서도 원스톱 설치 지원

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 글로벌 변수
PYTHON_MIN_VERSION="3.11"
DOCKER_MIN_VERSION="20.0"
COMPOSE_MIN_VERSION="2.0"

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

log_install() {
    echo -e "${CYAN}[INSTALL]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🏗️ Blueprint v17.0 DEV Environment Setup"
    echo "\"완전한 실험실\" 철학 구현"
    echo "Zero Setup: 완전히 새로운 컴퓨터에서도 원스톱 설치"
    echo "PostgreSQL + Redis + MLflow + Feast"
    echo "=================================================================="
    echo -e "${NC}"
}

# 운영체제 감지
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            DISTRO=$(cat /etc/redhat-release | awk '{print $1}')
        else
            OS="linux"
            DISTRO="Unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="Windows"
    else
        OS="unknown"
        DISTRO="Unknown"
    fi
    
    log_info "감지된 운영체제: $DISTRO ($OS)"
}

# 버전 비교 함수
version_compare() {
    local version1=$1
    local version2=$2
    printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1
}

# Docker 설치 확인 및 설치
install_docker() {
    log_step "Docker 설치 확인 중..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local min_version_check=$(version_compare "$docker_version" "$DOCKER_MIN_VERSION")
        
        if [ "$min_version_check" = "$DOCKER_MIN_VERSION" ]; then
            log_success "Docker $docker_version 이미 설치됨"
        else
            log_warn "Docker 버전이 너무 낮습니다 ($docker_version < $DOCKER_MIN_VERSION)"
            install_docker_package
        fi
    else
        log_install "Docker 설치 중..."
        install_docker_package
    fi
    
    # Docker 서비스 확인
    if ! docker info &> /dev/null; then
        log_warn "Docker 서비스가 실행되고 있지 않습니다."
        start_docker_service
    fi
}

install_docker_package() {
    case $OS in
        "macos")
            if command -v brew &> /dev/null; then
                log_install "Homebrew로 Docker 설치 중..."
                brew install --cask docker
                log_info "Docker Desktop을 수동으로 시작하세요"
                open /Applications/Docker.app
                log_info "Docker Desktop이 시작될 때까지 30초 대기..."
                sleep 30
            else
                log_error "Homebrew가 설치되어 있지 않습니다."
                log_info "Docker Desktop을 수동으로 설치하세요: https://docs.docker.com/desktop/install/mac-install/"
                exit 1
            fi
            ;;
        "debian")
            log_install "APT로 Docker 설치 중..."
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo usermod -aG docker $USER
            log_warn "Docker 그룹 변경이 적용되도록 터미널을 재시작하거나 'newgrp docker'를 실행하세요"
            ;;
        "redhat")
            log_install "YUM/DNF로 Docker 설치 중..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            else
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            fi
            sudo usermod -aG docker $USER
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
        *)
            log_error "지원하지 않는 운영체제입니다: $OS"
            log_info "Docker를 수동으로 설치하세요: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
}

start_docker_service() {
    case $OS in
        "macos")
            log_info "Docker Desktop을 시작해주세요"
            if [ -d "/Applications/Docker.app" ]; then
                open /Applications/Docker.app
                log_info "Docker Desktop 시작 대기 중..."
                local retries=60
                while [ $retries -gt 0 ]; do
                    if docker info &> /dev/null; then
                        log_success "Docker Desktop 시작됨"
                        break
                    fi
                    sleep 5
                    retries=$((retries-5))
                done
            fi
            ;;
        "debian"|"redhat")
            log_install "Docker 서비스 시작 중..."
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
    esac
}

# Docker Compose 설치 확인
install_docker_compose() {
    log_step "Docker Compose 설치 확인 중..."
    
    # Docker Compose V2 (플러그인) 확인
    if docker compose version &> /dev/null; then
        local compose_version=$(docker compose version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_success "Docker Compose (Plugin) $compose_version 이미 설치됨"
        return
    fi
    
    # Docker Compose V1 확인
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local min_version_check=$(version_compare "$compose_version" "$COMPOSE_MIN_VERSION")
        
        if [ "$min_version_check" = "$COMPOSE_MIN_VERSION" ]; then
            log_success "Docker Compose $compose_version 이미 설치됨"
            return
        fi
    fi
    
    log_install "Docker Compose 설치 중..."
    case $OS in
        "macos")
            # Docker Desktop에 이미 포함됨
            log_info "Docker Desktop에 Docker Compose가 포함되어 있습니다"
            ;;
        "debian")
            sudo apt install -y docker-compose-plugin
            ;;
        "redhat")
            sudo yum install -y docker-compose-plugin
            ;;
        *)
            # Standalone 바이너리 설치
            local latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            sudo curl -L "https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
    esac
}

# Python 설치 확인 및 설치
install_python() {
    log_step "Python 설치 확인 중..."
    
    local python_cmd=""
    for cmd in python3 python; do
        if command -v $cmd &> /dev/null; then
            local python_version=$($cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
            local min_version_check=$(version_compare "$python_version" "$PYTHON_MIN_VERSION")
            
            if [ "$min_version_check" = "$PYTHON_MIN_VERSION" ]; then
                python_cmd=$cmd
                log_success "Python $python_version 이미 설치됨 ($cmd)"
                break
            fi
        fi
    done
    
    if [ -z "$python_cmd" ]; then
        log_install "Python $PYTHON_MIN_VERSION+ 설치 중..."
        install_python_package
        
        # 재확인
        for cmd in python3 python; do
            if command -v $cmd &> /dev/null; then
                local python_version=$($cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
                local min_version_check=$(version_compare "$python_version" "$PYTHON_MIN_VERSION")
                
                if [ "$min_version_check" = "$PYTHON_MIN_VERSION" ]; then
                    python_cmd=$cmd
                    break
                fi
            fi
        done
    fi
    
    if [ -z "$python_cmd" ]; then
        log_error "Python $PYTHON_MIN_VERSION+를 설치할 수 없습니다"
        exit 1
    fi
    
    # 전역 Python 명령어 설정
    export PYTHON_CMD=$python_cmd
}

install_python_package() {
    case $OS in
        "macos")
            if command -v brew &> /dev/null; then
                log_install "Homebrew로 Python 설치 중..."
                brew install python@3.11
            else
                log_error "Homebrew가 설치되어 있지 않습니다."
                log_info "Python을 수동으로 설치하세요: https://www.python.org/downloads/"
                exit 1
            fi
            ;;
        "debian")
            log_install "APT로 Python 설치 중..."
            sudo apt update
            sudo apt install -y python3.11 python3.11-pip python3.11-venv python3-pip
            ;;
        "redhat")
            log_install "YUM/DNF로 Python 설치 중..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y python3.11 python3-pip
            else
                sudo yum install -y python3.11 python3-pip
            fi
            ;;
        *)
            log_error "지원하지 않는 운영체제입니다: $OS"
            log_info "Python을 수동으로 설치하세요: https://www.python.org/downloads/"
            exit 1
            ;;
    esac
}

# Python 패키지 설치
install_python_packages() {
    log_step "Python 패키지 설치 중..."
    
    # pip 업그레이드
    log_install "pip 업그레이드 중..."
    $PYTHON_CMD -m pip install --upgrade pip
    
    # 필수 패키지 설치
    log_install "필수 패키지 설치 중..."
    local packages=(
        "feast[redis,postgres]>=0.32.0"
        "mlflow>=2.10.0"
        "psycopg2-binary"
        "redis"
        "requests"
        "pyyaml"
    )
    
    for package in "${packages[@]}"; do
        log_info "설치 중: $package"
        $PYTHON_CMD -m pip install "$package" || log_warn "$package 설치 실패 - 계속 진행"
    done
    
    log_success "Python 패키지 설치 완료"
}

# 필요한 디렉토리 생성
create_directories() {
    log_step "디렉토리 구조 생성 중..."
    
    mkdir -p config/mlflow
    mkdir -p config/pgadmin  
    mkdir -p sql/{init,schemas}
    
    # Blueprint v17.0 호환성: feast 디렉토리 제거
    if [ -d "feast" ]; then
        log_warn "Blueprint v17.0 호환성: 기존 feast 디렉토리 제거 중..."
        rm -rf feast
    fi
    
    log_success "디렉토리 구조가 생성되었습니다."
}

# 기존 환경 정리
cleanup_existing() {
    log_step "기존 환경 정리 중..."
    
    # Docker Compose 명령어 감지
    local compose_cmd="docker compose"
    if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    # 컨테이너 중지 및 제거
    $compose_cmd down -v 2>/dev/null || true
    
    # 네트워크 정리
    docker network rm ml-pipeline-db-network 2>/dev/null || true
    
    # 고아 컨테이너 정리
    docker container prune -f 2>/dev/null || true
    
    log_success "기존 환경이 정리되었습니다."
}

# DB 서비스 시작
start_services() {
    log_step "데이터베이스 서비스 시작 중..."
    
    # Docker Compose 명령어 감지
    local compose_cmd="docker compose"
    if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    log_info "사용하는 Docker Compose: $compose_cmd"
    
    # 서비스 시작
    $compose_cmd up -d
    
    log_success "데이터베이스 서비스가 시작되었습니다."
}

# 서비스 상태 확인
check_services() {
    log_step "서비스 상태 확인 중..."
    
    # Docker Compose 명령어 감지
    local compose_cmd="docker compose"
    if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        compose_cmd="docker-compose"
    fi
    
    # PostgreSQL 연결 확인
    log_info "PostgreSQL 연결 확인 중..."
    local retries=60
    while [ $retries -gt 0 ]; do
        if $compose_cmd exec -T postgres pg_isready -U mluser -d mlpipeline >/dev/null 2>&1; then
            log_success "PostgreSQL 연결 성공"
            break
        fi
        log_info "PostgreSQL 연결 대기 중... ($retries초 남음)"
        retries=$((retries-1))
        sleep 2
    done
    
    if [ $retries -eq 0 ]; then
        log_error "PostgreSQL 연결 실패"
        $compose_cmd logs postgres
        exit 1
    fi
    
    # Redis 연결 확인
    log_info "Redis 연결 확인 중..."
    retries=30
    while [ $retries -gt 0 ]; do
        if $compose_cmd exec -T redis redis-cli ping >/dev/null 2>&1; then
            log_success "Redis 연결 성공"
            break
        fi
        log_info "Redis 연결 대기 중... ($retries초 남음)"
        retries=$((retries-1))
        sleep 2
    done
    
    if [ $retries -eq 0 ]; then
        log_error "Redis 연결 실패"
        $compose_cmd logs redis
        exit 1
    fi
    
    # MLflow 서버 확인
    log_info "MLflow 서버 확인 중..."
    retries=90
    while [ $retries -gt 0 ]; do
        if curl -f http://localhost:5000/health >/dev/null 2>&1; then
            log_success "MLflow 서버 연결 성공"
            break
        fi
        log_info "MLflow 서버 시작 대기 중... ($retries초 남음)"
        retries=$((retries-1))
        sleep 2
    done
    
    if [ $retries -eq 0 ]; then
        log_warn "MLflow 서버 연결 실패 - 서비스 로그를 확인하세요"
        log_info "로그 확인: $compose_cmd logs mlflow"
    fi
}

# 환경 검증
verify_environment() {
    log_step "환경 검증 중..."
    
    # 서비스 포트 확인
    local services=(
        "5432:PostgreSQL"
        "6379:Redis" 
        "5000:MLflow"
        "8082:pgAdmin"
        "8081:Redis Commander"
    )
    
    for service in "${services[@]}"; do
        local port=$(echo $service | cut -d: -f1)
        local name=$(echo $service | cut -d: -f2)
        
        if netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i :$port >/dev/null 2>&1 || ss -tuln 2>/dev/null | grep -q ":$port "; then
            log_success "$name ($port) 포트 활성"
        else
            log_warn "$name ($port) 포트 비활성 - 서비스 확인 필요"
        fi
    done
    
    # Python 패키지 확인
    log_info "Python 패키지 확인 중..."
    local required_packages=("feast" "mlflow" "psycopg2" "redis")
    
    for package in "${required_packages[@]}"; do
        if $PYTHON_CMD -c "import $package" 2>/dev/null; then
            log_success "Python 패키지 $package 설치됨"
        else
            log_warn "Python 패키지 $package 설치되지 않음"
        fi
    done
}

# 추가 도구 설치 제안
suggest_additional_tools() {
    log_step "추가 도구 설치 제안..."
    
    local suggestions=()
    
    # netstat 확인
    if ! command -v netstat &> /dev/null && ! command -v ss &> /dev/null; then
        suggestions+=("net-tools (netstat)")
    fi
    
    # curl 확인
    if ! command -v curl &> /dev/null; then
        suggestions+=("curl")
    fi
    
    # lsof 확인
    if ! command -v lsof &> /dev/null; then
        suggestions+=("lsof")
    fi
    
    if [ ${#suggestions[@]} -gt 0 ]; then
        log_info "추가 설치를 권장하는 도구들:"
        for tool in "${suggestions[@]}"; do
            echo "  - $tool"
        done
        
        case $OS in
            "debian")
                log_info "설치 명령어: sudo apt install -y net-tools curl lsof"
                ;;
            "redhat")
                log_info "설치 명령어: sudo yum install -y net-tools curl lsof"
                ;;
            "macos")
                log_info "설치 명령어: brew install curl lsof"
                ;;
        esac
    fi
}

# 환경 정보 출력
print_environment_info() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🎉 Blueprint v17.0 DEV 환경이 준비되었습니다!"
    echo "\"완전한 실험실\" 철학 구현 완료"
    echo "=================================================================="
    echo -e "${NC}"
    
    echo "📱 서비스 접속 정보:"
    echo "   🗄️  PostgreSQL:         localhost:5432 (mluser/mlpassword/mlpipeline)"
    echo "   🔴 Redis:              localhost:6379"
    echo "   📊 MLflow:             http://localhost:5000"
    echo "   🐘 pgAdmin:            http://localhost:8082 (admin@mlpipeline.local/admin)"
    echo "   🔧 Redis Commander:    http://localhost:8081 (admin/admin)"
    echo ""
    
    echo "🔌 ML Pipeline 프로젝트 연결:"
    echo "   # DEV 환경으로 학습 실행"
    echo "   cd ../modern-ml-pipeline"
    echo "   APP_ENV=dev python main.py train --recipe-file models/classification/random_forest_classifier"
    echo ""
    echo "   # DEV 환경으로 API 서빙"  
    echo "   APP_ENV=dev python main.py serve-api --run-id <run_id>"
    echo ""
    
    echo "🏪 Feature Store 사용법 (Blueprint v17.0):"
    echo "   # ML Pipeline 프로젝트의 config/dev.yaml에 이미 feast_config 포함됨"
    echo "   # Recipe에서 피처 선언:"
    echo "   augmenter:"
    echo "     type: \"feature_store\""
    echo "     features:"
    echo "       - feature_namespace: \"user_demographics\""
    echo "         features: [\"age\", \"country_code\"]"
    echo "       - feature_namespace: \"product_details\""
    echo "         features: [\"price\", \"category\"]"
    echo ""
    
    echo "🛠️ 관리 명령어:"
    echo "   # 서비스 상태 확인"
    echo "   ./setup.sh --status"
    echo ""
    echo "   # 로그 확인"
    echo "   ./setup.sh --logs"
    echo ""
    echo "   # 서비스 재시작"
    echo "   docker-compose restart  # 또는 docker compose restart"
    echo ""
    echo "   # 서비스 중지"
    echo "   docker-compose down"
    echo ""
    echo "   # 완전 정리 (데이터 삭제)"
    echo "   ./setup.sh --clean"
    echo ""
    
    echo "🧪 환경 검증:"
    echo "   ./setup.sh --status  # 전체 환경 상태 확인"
    echo "   docker-compose ps    # 컨테이너 상태 확인"
    echo "   curl http://localhost:5000/health  # MLflow 상태 확인"
    echo ""
}

# 메인 실행
main() {
    print_banner
    detect_os
    install_docker
    install_docker_compose
    install_python
    install_python_packages
    create_directories
    cleanup_existing
    start_services
    check_services
    verify_environment
    suggest_additional_tools
    print_environment_info
    
    log_success "Blueprint v17.0 DEV 환경 설정이 완료되었습니다! 🎉"
    log_info "이제 ML Pipeline에서 APP_ENV=dev로 모든 기능을 사용할 수 있습니다."
}

# 옵션 처리
case "${1:-}" in
    --clean)
        print_banner
        log_info "환경 정리 중..."
        
        # Docker Compose 명령어 감지
        local compose_cmd="docker compose"
        if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            compose_cmd="docker-compose"
        fi
        
        $compose_cmd down -v
        docker system prune -f
        docker volume prune -f
        
        log_success "환경 정리 완료"
        exit 0
        ;;
    --logs)
        # Docker Compose 명령어 감지
        local compose_cmd="docker compose"
        if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            compose_cmd="docker-compose"
        fi
        
        $compose_cmd logs -f
        exit 0
        ;;
    --status)
        print_banner
        echo "서비스 상태:"
        
        # Docker Compose 명령어 감지
        local compose_cmd="docker compose"
        if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            compose_cmd="docker-compose"
        fi
        
        $compose_cmd ps
        echo ""
        
        detect_os
        verify_environment
        exit 0
        ;;
    --install-deps)
        print_banner
        log_info "의존성만 설치 중..."
        detect_os
        install_docker
        install_docker_compose
        install_python
        install_python_packages
        log_success "의존성 설치 완료"
        exit 0
        ;;
    --help)
        echo "Blueprint v17.0 DEV Environment Setup"
        echo ""
        echo "사용법: $0 [옵션]"
        echo ""
        echo "옵션:"
        echo "  (없음)           전체 환경 설치 및 시작"
        echo "  --install-deps   의존성만 설치 (Docker, Python, 패키지)"
        echo "  --clean          환경 완전 정리 (데이터 삭제)"
        echo "  --logs           모든 서비스 로그 확인"
        echo "  --status         서비스 상태 확인"
        echo "  --help           도움말 표시"
        echo ""
        echo "Blueprint v17.0 \"완전한 실험실\" 철학:"
        echo "  - PostgreSQL: Loader SQL + Feast Offline Store"
        echo "  - Redis: Feast Online Store"
        echo "  - MLflow: 팀 공유 실험 추적"
        echo "  - Feast: Feature Store 프레임워크"
        echo ""
        echo "지원 운영체제:"
        echo "  - macOS (Homebrew)"
        echo "  - Ubuntu/Debian (APT)"
        echo "  - RHEL/CentOS/Fedora (YUM/DNF)"
        echo ""
        echo "자동 설치 항목:"
        echo "  - Docker & Docker Compose"
        echo "  - Python 3.11+"
        echo "  - Feast, MLflow, Redis, PostgreSQL 패키지"
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
# 🏗️ ML Pipeline Local Database Environment (Blueprint v17.0)

## 📋 개요

**"완전한 실험실" 철학 구현**

이 환경은 [Modern ML Pipeline Blueprint v17.0](https://github.com/your-org/modern-ml-pipeline)의 **DEV 환경**을 완전하게 구현하는 독립적인 데이터베이스 스택입니다. 팀 공유가 가능한 완전한 Feature Store, MLflow 실험 추적, 그리고 모든 Blueprint 기능을 지원하는 통합 개발 환경을 제공합니다.

### 🎯 Blueprint v17.0 "DEV 환경" 철학

```yaml
철학: "모든 기능이 완전히 작동하는 안전한 실험실"
특징:
  - 완전 기능: 모든 파이프라인 컴포넌트 지원
  - 팀 공유: 통합된 Feature Store와 MLflow
  - 실제 환경: PROD와 동일한 아키텍처, 다른 스케일
  - 안전한 실험: 운영에 영향 없는 독립 환경

동작 방식:
  Data Loading: PostgreSQL SQL 실행
  Feature Store: PostgreSQL(Offline) + Redis(Online) + Feast
  기능 지원: 모든 기능 완전 지원
  MLflow: 팀 공유 서버
```

---

## 🏗️ 아키텍처 구성

### 핵심 서비스 스택

| 서비스 | 역할 | 포트 | Blueprint 원칙 |
|--------|------|------|----------------|
| **PostgreSQL** | Data Warehouse + Feast Offline Store + MLflow Backend | 5432 | 원칙 2: 통합 데이터 어댑터 |
| **Redis** | Feast Online Store + 캐싱 | 6379 | 원칙 5: 컨텍스트 주입 Augmenter |
| **MLflow** | 팀 공유 실험 추적 및 모델 관리 | 5000 | 원칙 1: 레시피는 논리, 설정은 인프라 |
| **pgAdmin** | PostgreSQL 관리 UI | 8082 | 개발 편의성 |
| **Redis Commander** | Redis 관리 UI | 8081 | 개발 편의성 |

### 데이터 구조

```
PostgreSQL Database (mlpipeline)
├── public.*                 # MLflow backend store (자동 생성)
├── feature_mart.*          # Feature Store 데이터 (Blueprint 네임스페이스)
│   ├── user_demographics   # 사용자 인구통계 피처
│   ├── user_purchase_summary # 사용자 구매 요약 피처  
│   ├── product_details     # 상품 상세 피처
│   └── session_summary     # 세션 요약 피처
├── spine_data.*            # Loader SQL용 Spine 데이터
│   ├── user_spine         # 사용자 엔티티 뼈대
│   ├── product_spine      # 상품 엔티티 뼈대
│   └── session_spine      # 세션 엔티티 뼈대
└── raw_data.*             # 원시 데이터 (미래 확장)

Redis (Key-Value Store)
├── feature_store:*         # Feast Online Store
├── user_demographics:*     # 사용자 인구통계 피처 캐시
├── product_details:*       # 상품 피처 캐시
└── cache:*                # 일반 캐싱
```

---

## 🚀 빠른 시작 (Zero Setup)

### 1단계: 사전 요구사항 자동 확인

완전히 새로운 컴퓨터에서도 원스톱 설치가 가능합니다.

```bash
# 저장소 복제
git clone https://github.com/your-org/mmp-local-dev.git
cd mmp-local-dev

# 원스톱 설치 (모든 의존성 자동 설치)
./setup.sh
```

**setup.sh가 자동으로 확인/설치하는 것들:**
- ✅ Docker & Docker Compose 설치 여부
- ✅ Python 3.11+ 설치 여부  
- ✅ 필요한 Python 패키지 (feast, mlflow)
- ✅ 환경 설정 및 초기화
- ✅ 서비스 상태 검증
- ✅ 테스트 데이터 생성

### 2단계: 설치 완료 확인

설치가 완료되면 다음과 같은 출력을 확인할 수 있습니다:

```
🎉 Blueprint v17.0 DEV 환경이 준비되었습니다!
================================================================

📱 서비스 접속 정보:
   🗄️  PostgreSQL:         localhost:5432 (mluser/mlpassword/mlpipeline)
   🔴 Redis:              localhost:6379
   📊 MLflow:             http://localhost:5000
   🐘 pgAdmin:            http://localhost:8082 (admin@mlpipeline.local/admin)
   🔧 Redis Commander:    http://localhost:8081 (admin/admin)
```

### 3단계: ML Pipeline 프로젝트 연결

```bash
# ML Pipeline 프로젝트로 이동
cd ../modern-ml-pipeline

# DEV 환경으로 학습 실행 (Blueprint 전체 기능 사용)
APP_ENV=dev python main.py train --recipe-file models/classification/random_forest_classifier

# DEV 환경으로 API 서빙 (실시간 Feature Store 조회)
APP_ENV=dev python main.py serve-api --run-id <run_id>
```

---

## 🔧 상세 설치 가이드

### Option A: 자동 설치 (권장)

```bash
# 모든 의존성을 자동으로 설치하고 환경을 구성
./setup.sh

# 설치 과정 로그 확인
./setup.sh --logs

# 환경 상태 확인
./setup.sh --status
```

### Option B: 수동 설치

완전한 제어가 필요한 경우 수동으로 설치할 수 있습니다.

#### 1. Docker 설치

**macOS (Homebrew):**
```bash
brew install docker docker-compose
brew install --cask docker
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker
```

**Windows:**
- [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) 다운로드 및 설치

#### 2. Python 환경 설정

```bash
# Python 3.11+ 설치 확인
python3 --version

# 가상환경 생성 (선택사항)
python3 -m venv ml-pipeline-env
source ml-pipeline-env/bin/activate  # Linux/macOS
# 또는 ml-pipeline-env\Scripts\activate  # Windows

# 필수 패키지 설치
pip install feast[redis,postgres]>=0.32.0
pip install mlflow>=2.10.0
pip install psycopg2-binary
```

#### 3. 서비스 시작

```bash
# Docker Compose로 모든 서비스 시작
docker-compose up -d

# 서비스 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f
```

---

## 🏪 Feature Store 사용법

### Blueprint v17.0 네임스페이스 구조

이 환경은 Blueprint v17.0의 Feature Store 계약을 완전히 구현합니다:

```yaml
# Recipe에서 피처 선언 예시
augmenter:
  type: "feature_store"
  features:
    # 사용자 인구통계 피처
    - feature_namespace: "user_demographics"
      features: ["age", "country_code", "gender", "education_level"]
    
    # 사용자 구매 요약 피처
    - feature_namespace: "user_purchase_summary"  
      features: ["ltv", "total_purchase_count", "avg_order_value"]
    
    # 상품 상세 피처
    - feature_namespace: "product_details"
      features: ["price", "category", "brand", "avg_rating"]
    
    # 세션 요약 피처
    - feature_namespace: "session_summary"
      features: ["time_on_page_seconds", "click_count", "page_views"]
```

### Feast 초기화 및 구성

```bash
# ML Pipeline 프로젝트에서 Feast 적용
cd ../modern-ml-pipeline
feast apply  # config/dev.yaml의 feast_config 사용

# Feature Store 상태 확인
feast list-feature-services
feast get-feature-service <service_name>

# 피처 조회 테스트
feast materialize-incremental 2023-01-01T00:00:00 2023-12-31T23:59:59
```

---

## 📊 서비스 관리

### 기본 명령어

```bash
# 모든 서비스 상태 확인
docker-compose ps

# 특정 서비스 로그 확인
docker-compose logs -f mlflow
docker-compose logs -f postgres
docker-compose logs -f redis

# 서비스 재시작
docker-compose restart mlflow

# 모든 서비스 재시작
docker-compose restart

# 서비스 중지
docker-compose down

# 완전 정리 (모든 데이터 삭제)
docker-compose down -v
```

### 고급 관리

```bash
# PostgreSQL 직접 접속
docker-compose exec postgres psql -U mluser -d mlpipeline

# Redis 직접 접속
docker-compose exec redis redis-cli

# MLflow 컨테이너 내부 접속
docker-compose exec mlflow bash

# 디스크 사용량 확인
docker system df
```

### 백업 및 복원

```bash
# PostgreSQL 백업
docker-compose exec postgres pg_dump -U mluser mlpipeline > backup.sql

# PostgreSQL 복원
docker-compose exec postgres psql -U mluser mlpipeline < backup.sql

# Redis 백업 (AOF 파일 복사)
docker cp ml-pipeline-redis:/data/appendonly.aof redis-backup.aof
```

---

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 포트 충돌 오류

```bash
# 포트 사용 중인 프로세스 확인
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis  
lsof -i :5000  # MLflow

# 기존 서비스 중지
sudo kill -9 <PID>

# 또는 Docker에서 포트 변경
# docker-compose.yml 수정 후 재시작
```

#### 2. 서비스 시작 실패

```bash
# 전체 환경 정리 후 재시작
./setup.sh --clean
./setup.sh

# 또는 수동으로
docker-compose down -v
docker system prune -f
docker-compose up -d
```

#### 3. Feature Store 연결 오류

```bash
# PostgreSQL 연결 확인
docker-compose exec postgres pg_isready -U mluser

# Redis 연결 확인  
docker-compose exec redis redis-cli ping

# Feast 구성 재적용
cd ../modern-ml-pipeline
feast apply
```

#### 4. MLflow 접속 불가

```bash
# MLflow 서비스 로그 확인
docker-compose logs mlflow

# 수동으로 MLflow 재시작
docker-compose restart mlflow

# 브라우저에서 확인: http://localhost:5000
```

### 성능 최적화

```bash
# Docker 리소스 정리
docker system prune -f

# PostgreSQL 성능 튜닝 (config/postgres.conf 수정)
# shared_buffers = 256MB
# effective_cache_size = 1GB

# Redis 메모리 사용량 확인
docker-compose exec redis redis-cli info memory
```

---

## 🧪 테스트 및 검증

### 환경 검증 스크립트

```bash
# 전체 환경 검증
./setup.sh --status

# 수동 검증
python3 << EOF
import psycopg2
import redis
import requests

# PostgreSQL 연결 테스트
try:
    conn = psycopg2.connect(
        host="localhost", port=5432, 
        database="mlpipeline", user="mluser", password="mlpassword"
    )
    print("✅ PostgreSQL 연결 성공")
    conn.close()
except Exception as e:
    print(f"❌ PostgreSQL 연결 실패: {e}")

# Redis 연결 테스트
try:
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.ping()
    print("✅ Redis 연결 성공")
except Exception as e:
    print(f"❌ Redis 연결 실패: {e}")

# MLflow 서버 테스트
try:
    response = requests.get("http://localhost:5000/health")
    if response.status_code == 200:
        print("✅ MLflow 서버 연결 성공")
    else:
        print(f"❌ MLflow 서버 응답 오류: {response.status_code}")
except Exception as e:
    print(f"❌ MLflow 서버 연결 실패: {e}")
EOF
```

### Blueprint 통합 테스트

```bash
# ML Pipeline 프로젝트에서 DEV 환경 전체 워크플로우 테스트
cd ../modern-ml-pipeline

# 1. 학습 테스트 (Feature Store 포함)
APP_ENV=dev python main.py train --recipe-file models/classification/random_forest_classifier

# 2. 배치 추론 테스트
APP_ENV=dev python main.py batch-inference --run-id <latest_run_id> --input-file data/test.parquet

# 3. API 서빙 테스트
APP_ENV=dev python main.py serve-api --run-id <latest_run_id> &
sleep 5
curl -X POST "http://localhost:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{"user_id": "user_001", "product_id": "prod_001", "session_id": "sess_001"}'
```

---

## 🔗 ML Pipeline 프로젝트 통합

### 프로젝트 구조

```
your-workspace/
├── modern-ml-pipeline/          # 메인 ML 파이프라인 프로젝트
│   ├── config/
│   │   ├── base.yaml           # feast_config 포함
│   │   ├── dev.yaml            # DEV 환경 설정 (이 환경 참조)
│   │   └── prod.yaml
│   ├── recipes/
│   └── src/
└── mmp-local-dev/        # 독립적인 DEV 환경 (이 저장소)
    ├── docker-compose.yml
    ├── setup.sh
    └── README.md
```

### 환경 설정 연동

ML Pipeline 프로젝트의 `config/dev.yaml`에서 이 환경을 참조하도록 설정:

```yaml
# modern-ml-pipeline/config/dev.yaml
feast_config:
  provider: "local"
  registry:
    registry_type: "sql"
    path: "postgresql://mluser:mlpassword@localhost:5432/mlpipeline"
  offline_store:
    type: "postgres"
    host: "localhost"
    port: 5432
    database: "mlpipeline"
    user: "mluser"
    password: "mlpassword"
  online_store:
    type: "redis"
    connection_string: "redis://localhost:6379"

mlflow:
  tracking_uri: "http://localhost:5000"
  experiment_name: "DEV-Environment-Experiments"
```

---

## 📚 추가 리소스

### Blueprint v17.0 문서
- [Blueprint v17.0 전체 문서](../modern-ml-pipeline/blueprint.md)
- [Feature Store Contract](../modern-ml-pipeline/feature_store_contract.md)
- [Developer Guide](../modern-ml-pipeline/developer_guide.md)

### 외부 문서
- [Feast Documentation](https://docs.feast.dev/)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

### 커뮤니티
- [Blueprint v17.0 GitHub Issues](https://github.com/your-org/modern-ml-pipeline/issues)
- [Feature Store Best Practices](https://github.com/feast-dev/feast)

---

## 🤝 기여하기

이 환경 개선에 기여하고 싶다면:

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### 개선 아이디어
- [ ] 자동 백업 스케줄링
- [ ] 모니터링 대시보드 추가
- [ ] 성능 벤치마킹 도구
- [ ] 다중 환경 지원 (staging, qa)
- [ ] 클라우드 배포 스크립트

---

## 📄 라이선스

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**🌟 Blueprint v17.0의 "완전한 실험실" 철학을 구현한 DEV 환경에서 ML 개발의 새로운 경험을 시작하세요!** 
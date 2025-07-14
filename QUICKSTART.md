# 🚀 5분 빠른 시작 가이드

## Blueprint v17.0 "완전한 실험실" 5분 만에 시작하기

### 1단계: 환경 복제 및 설치 (2분)

```bash
# 1. 저장소 복제
git clone https://github.com/your-org/ml-pipeline-local-db.git
cd ml-pipeline-local-db

# 2. 원스톱 자동 설치 (모든 의존성 자동 설치)
./setup.sh
```

**자동으로 설치되는 것들:**
- ✅ Docker & Docker Compose (없으면 자동 설치)
- ✅ Python 3.11+ (없으면 자동 설치)
- ✅ PostgreSQL + Redis + MLflow (컨테이너로 자동 시작)
- ✅ Feature Store 테스트 데이터 (자동 생성)
- ✅ Feast, MLflow 등 Python 패키지 (자동 설치)

### 2단계: 환경 검증 (1분)

```bash
# 전체 환경 통합 테스트
./test-environment.sh
```

**성공하면 이런 메시지를 볼 수 있습니다:**
```
🎉 모든 테스트가 성공했습니다!
Blueprint v17.0 DEV 환경이 완벽하게 구성되었습니다.
```

### 3단계: ML Pipeline 연결 및 실행 (2분)

```bash
# ML Pipeline 프로젝트로 이동
cd ../modern-ml-pipeline

# DEV 환경으로 첫 번째 학습 실행 (Feature Store 포함)
APP_ENV=dev python main.py train --recipe-file models/classification/random_forest_classifier

# 학습 결과 확인 (MLflow UI)
# 브라우저에서 http://localhost:5000 접속
```

## 🎯 완료! 이제 다음을 사용할 수 있습니다

### 📊 관리 도구 접속
- **MLflow UI**: http://localhost:5000 (실험 추적)
- **pgAdmin**: http://localhost:8082 (PostgreSQL 관리)
- **Redis Commander**: http://localhost:8081 (Redis 관리)

### 🏪 Feature Store 활용
```yaml
# Recipe에서 피처 선언 예시
augmenter:
  type: "feature_store"
  features:
    - feature_namespace: "user_demographics"
      features: ["age", "country_code"]
    - feature_namespace: "product_details" 
      features: ["price", "category"]
```

### 🔄 일상적인 사용법
```bash
# DEV 환경으로 새 모델 실험
APP_ENV=dev python main.py train --recipe-file models/regression/lightgbm_regressor

# 배치 추론 실행
APP_ENV=dev python main.py batch-inference --run-id <run_id>

# API 서빙 시작
APP_ENV=dev python main.py serve-api --run-id <run_id>
```

## 🛠️ 문제 해결

```bash
# 서비스 상태 확인
cd ../ml-pipeline-local-db
./setup.sh --status

# 로그 확인
./setup.sh --logs

# 완전 재설치
./setup.sh --clean && ./setup.sh
```

## 🎉 축하합니다!

Blueprint v17.0의 "완전한 실험실" DEV 환경이 준비되었습니다. 이제 Feature Store, MLflow, 그리고 모든 Blueprint 기능을 완전히 활용할 수 있습니다!

**다음 단계:**
- [전체 문서 읽기](README.md)
- [Blueprint v17.0 문서](../modern-ml-pipeline/blueprint.md)
- [Feature Store 사용법](../modern-ml-pipeline/feature_store_contract.md) 

## 🎯 추천 방법들 (우선순위별)

### 1. **Git Submodule 방식** (⭐ 가장 세련된 표준 방법)

메인 프로젝트에서 ml-pipeline-local-db를 submodule로 관리하는 방법입니다.

```bash
<code_block_to_apply_changes_from>
```

**사용자 경험:**
```bash
# 사용자가 clone할 때
git clone --recursive https://github.com/your-org/modern-ml-pipeline.git
cd modern-ml-pipeline/dev-environment
./setup.sh

# 또는 기존 clone에서
git submodule update --init --recursive
```

**장점:**
- ✅ 표준적이고 Git 네이티브한 방법
- ✅ 각 repo가 독립적으로 버전 관리됨
- ✅ main project가 깔끔하게 유지됨
- ✅ submodule 업데이트가 선택적

### 2. **원스톱 개발환경 스크립트** (⭐ 사용자 편의성 최고)

```bash
# ml-pipeline-local-db를 별도 GitHub repo로 생성 후
cd modern-ml-pipeline
git submodule add https://github.com/your-org/ml-pipeline-local-db.git dev-environment
git commit -m "Add dev environment as submodule"
``` 
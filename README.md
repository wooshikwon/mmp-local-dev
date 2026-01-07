# MMP Local Development Environment

Modern ML Pipeline 로컬 개발 환경 - Docker Compose 기반

## 구성 요소

| 서비스 | 포트 | 용도 |
|--------|------|------|
| PostgreSQL | 5432 | Feature Store Offline Store / 데이터 저장소 |
| Redis | 6379 | Feature Store Online Store / 캐시 |
| MLflow | 5000 | 실험 추적 및 모델 레지스트리 |

## 빠른 시작

### 1. 환경 설정

```bash
# 환경 변수 파일 생성
cp .env.example .env

# 필요시 .env 수정
```

### 2. 서비스 시작

```bash
docker-compose up -d
```

### 3. 서비스 확인

```bash
docker-compose ps
```

## Fraud Detection 데이터셋

Point-in-Time Join 테스트를 위한 신용카드 사기 탐지 데이터셋이 포함되어 있습니다.

### 데이터셋 정보

- **출처**: [Kaggle Credit Card Transactions Fraud Detection](https://www.kaggle.com/datasets/kartik2112/fraud-detection)
- **기간**: 2019-01-01 ~ 2020-06-21
- **크기**: 50,000 거래 (샘플링)
- **Fraud 비율**: ~1.16%

### 테이블 구조

| 테이블 | 설명 | Point-in-Time |
|--------|------|---------------|
| `transactions` | 거래 이벤트 (Entity DataFrame) | event_timestamp |
| `user_features` | 사용자 거래 통계 (시간에 따라 변함) | created_at |
| `user_demographics` | 사용자 인구통계 | created_at |
| `merchant_features` | 머천트 특성 | created_at |
| `category_features` | 카테고리 통계 | created_at |

### 전체 셋업

```bash
# 1. Kaggle 데이터 다운로드 (API 키 필요)
kaggle datasets download -d kartik2112/fraud-detection -p data --unzip

# 2. 전체 셋업 실행
./setup-fraud-detection.sh
```

### 수동 셋업

```bash
# 1. Docker Compose 시작
docker-compose up -d

# 2. 데이터 전처리
python3 scripts/prepare_fraud_data.py

# 3. PostgreSQL 데이터 로드
bash scripts/load_fraud_data.sh

# 4. Feast 적용
cd feast && feast apply && cd ..
```

### Point-in-Time Join 테스트

```bash
python3 scripts/test_point_in_time_join.py
```

## Feast Feature Store

### Feature Views

| Feature View | Entity | 피처 수 | 설명 |
|--------------|--------|---------|------|
| `user_demographics` | user_id | 9 | 사용자 인구통계 |
| `user_transaction_features` | user_id | 15 | 시간별 거래 통계 |
| `merchant_features` | merchant_id | 10 | 머천트 특성 |
| `category_features` | category | 7 | 카테고리 통계 |

### Point-in-Time Join 예시

```python
from feast import FeatureStore
import pandas as pd

store = FeatureStore(repo_path="feast")

# Entity DataFrame (거래 이벤트)
entity_df = pd.DataFrame({
    "user_id": ["user_abc123", "user_def456"],
    "event_timestamp": ["2019-06-15 10:00:00", "2019-08-20 14:30:00"]
})

# 피처 조회 (각 거래 시점 기준)
training_df = store.get_historical_features(
    entity_df=entity_df,
    features=[
        "user_transaction_features:avg_amount",
        "user_transaction_features:transactions_7d",
        "user_demographics:age",
    ],
).to_df()
```

## 디렉토리 구조

```
mmp-local-dev/
├── docker-compose.yml      # Docker 서비스 정의
├── .env.example            # 환경 변수 템플릿
├── setup-fraud-detection.sh # 전체 셋업 스크립트
├── feast/
│   ├── feature_store.yaml  # Feast 설정
│   └── features.py         # Feature View 정의
├── scripts/
│   ├── init-database.sql   # DB 초기화
│   ├── prepare_fraud_data.py # 데이터 전처리
│   ├── load_fraud_data.sh  # 데이터 로드
│   └── test_point_in_time_join.py # PIT 테스트
└── data/
    ├── fraudTrain.csv      # Kaggle 원본
    └── processed/          # 전처리된 데이터
```

## modern-ml-pipeline과 연동

```yaml
# configs/local-dev.yaml
feature_store:
  provider: feast
  feast_config:
    project: ml_pipeline_local
    registry: /path/to/mmp-local-dev/feast/data/registry.db
    online_store:
      type: redis
      connection_string: redis://localhost:6379
    offline_store:
      type: postgres
      host: localhost
      port: 5432
      database: mlpipeline
      db_schema: features
      user: mluser
      password: mlpassword
```

## 서비스 관리

```bash
# 시작
docker-compose up -d

# 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f

# 중지
docker-compose down

# 볼륨 포함 삭제
docker-compose down -v
```

## 문제 해결

### PostgreSQL 연결 실패

```bash
# 연결 테스트
PGPASSWORD=mlpassword psql -h localhost -p 5432 -U mluser -d mlpipeline -c "SELECT 1;"
```

### Feast 오류

```bash
# Feast 재설치
pip install feast[postgres] --upgrade

# Registry 초기화
rm -f feast/data/registry.db
cd feast && feast apply && cd ..
```

## 라이선스

MIT License

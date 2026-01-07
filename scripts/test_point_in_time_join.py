#!/usr/bin/env python3
"""
Point-in-Time Join 테스트 스크립트

Feast를 사용하여 거래 시점 기준으로 피처를 조회하는 테스트
- 각 거래(event)에 대해 해당 시점까지의 사용자 피처만 조회
- 미래 데이터 누출(data leakage) 방지 확인
"""

import pandas as pd
import os
from pathlib import Path
from datetime import datetime

# Feast 임포트
try:
    from feast import FeatureStore
except ImportError:
    print("Feast가 설치되어 있지 않습니다.")
    print("설치: pip install feast[postgres]")
    exit(1)

# 경로 설정
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
FEAST_REPO = PROJECT_DIR / "feast"
DATA_DIR = PROJECT_DIR / "data" / "processed"


def load_entity_dataframe():
    """거래 이벤트 데이터 로드 (Entity DataFrame)"""
    transactions = pd.read_csv(DATA_DIR / "transactions.csv")
    transactions['event_timestamp'] = pd.to_datetime(transactions['event_timestamp'])

    # 샘플 추출 (테스트용)
    sample = transactions.sample(n=100, random_state=42).copy()
    sample = sample.sort_values('event_timestamp').reset_index(drop=True)

    print(f"Entity DataFrame: {len(sample)} 거래")
    print(f"기간: {sample['event_timestamp'].min()} ~ {sample['event_timestamp'].max()}")
    print(f"Fraud 비율: {sample['is_fraud'].mean():.2%}")

    return sample


def test_point_in_time_join():
    """Point-in-Time Join 테스트"""
    print("=" * 60)
    print("Point-in-Time Join 테스트")
    print("=" * 60)
    print()

    # Feature Store 초기화
    print("Feature Store 초기화...")
    store = FeatureStore(repo_path=str(FEAST_REPO))

    # Entity DataFrame 로드
    print("\nEntity DataFrame 로드...")
    entity_df = load_entity_dataframe()

    # Entity DataFrame 준비 (Feast 형식)
    entity_df_for_feast = entity_df[['user_id', 'event_timestamp']].copy()

    print("\n사용자 피처 조회 중...")
    print("(각 거래 시점까지의 피처만 조회 - Point-in-Time 정확성)")

    # Point-in-Time Join 수행
    features = [
        "user_transaction_features:total_transactions",
        "user_transaction_features:avg_amount",
        "user_transaction_features:transactions_7d",
        "user_transaction_features:transactions_30d",
        "user_transaction_features:fraud_count",
        "user_demographics:age",
        "user_demographics:city_pop",
    ]

    training_df = store.get_historical_features(
        entity_df=entity_df_for_feast,
        features=features,
    ).to_df()

    print(f"\n결과: {len(training_df)} 행")

    # 결과 분석
    print("\n" + "=" * 60)
    print("Point-in-Time Join 결과 분석")
    print("=" * 60)

    # 원본 데이터와 조인
    result = entity_df.merge(
        training_df,
        on=['user_id', 'event_timestamp'],
        how='left'
    )

    print(f"\n컬럼: {list(result.columns)}")
    print(f"\n피처 통계:")
    feature_cols = [c for c in result.columns if c not in entity_df.columns]
    print(result[feature_cols].describe())

    # Point-in-Time 정확성 검증
    print("\n" + "=" * 60)
    print("Point-in-Time 정확성 검증")
    print("=" * 60)

    # 첫 번째 사용자의 거래 분석
    first_user = result['user_id'].iloc[0]
    user_txns = result[result['user_id'] == first_user].sort_values('event_timestamp')

    print(f"\n사용자 '{first_user}'의 거래별 피처 변화:")
    print("-" * 80)

    for idx, row in user_txns.head(5).iterrows():
        print(f"거래 시점: {row['event_timestamp']}")
        print(f"  - 총 거래 횟수: {row.get('total_transactions', 'N/A')}")
        print(f"  - 최근 7일 거래: {row.get('transactions_7d', 'N/A')}")
        print(f"  - 평균 금액: ${row.get('avg_amount', 0):.2f}")
        print()

    # 학습 데이터 저장
    output_path = DATA_DIR / "training_dataset.csv"
    result.to_csv(output_path, index=False)
    print(f"\n학습 데이터 저장: {output_path}")

    print("\n" + "=" * 60)
    print("테스트 완료!")
    print("=" * 60)

    return result


def main():
    # 환경 확인
    if not FEAST_REPO.exists():
        print(f"Error: Feast 저장소가 없습니다: {FEAST_REPO}")
        return

    if not (DATA_DIR / "transactions.csv").exists():
        print(f"Error: 거래 데이터가 없습니다: {DATA_DIR}")
        print("먼저 prepare_fraud_data.py를 실행하세요.")
        return

    # 테스트 실행
    result = test_point_in_time_join()

    # 학습 데이터 요약
    print("\n학습 데이터 요약:")
    print(f"  - 총 샘플: {len(result)}")
    print(f"  - Fraud 샘플: {result['is_fraud'].sum()}")
    print(f"  - 피처 수: {len([c for c in result.columns if c not in ['transaction_id', 'user_id', 'event_timestamp', 'is_fraud']])}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Fraud Detection 데이터 전처리 및 Feast용 피처 생성 스크립트

이 스크립트는 Kaggle Credit Card Fraud Detection 데이터를 처리하여:
1. 거래 이벤트 테이블 생성 (학습용 Entity DataFrame)
2. 시간에 따라 변하는 사용자 피처 생성 (Point-in-Time Join용)
3. 머천트/카테고리 피처 생성
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from pathlib import Path
import hashlib

DATA_DIR = Path(__file__).parent.parent / "data"
OUTPUT_DIR = DATA_DIR / "processed"
OUTPUT_DIR.mkdir(exist_ok=True)

# 샘플링 설정 (로컬 개발용)
SAMPLE_SIZE = 50000  # 전체 대신 50K 샘플 사용
RANDOM_STATE = 42


def load_and_sample_data():
    """데이터 로드 및 샘플링"""
    print("Loading data...")
    train = pd.read_csv(DATA_DIR / "fraudTrain.csv")

    # Fraud 비율 유지하면서 샘플링
    fraud = train[train['is_fraud'] == 1]
    non_fraud = train[train['is_fraud'] == 0]

    # Fraud는 모두 포함, 나머지는 비율 맞춰 샘플링
    fraud_ratio = len(fraud) / len(train)
    n_fraud = min(len(fraud), int(SAMPLE_SIZE * fraud_ratio * 2))  # fraud 비율 약간 높임
    n_non_fraud = SAMPLE_SIZE - n_fraud

    sampled = pd.concat([
        fraud.sample(n=n_fraud, random_state=RANDOM_STATE),
        non_fraud.sample(n=n_non_fraud, random_state=RANDOM_STATE)
    ]).sort_values('trans_date_trans_time').reset_index(drop=True)

    print(f"Sampled: {len(sampled):,} rows, {sampled['is_fraud'].sum():,} frauds ({sampled['is_fraud'].mean():.2%})")
    return sampled


def create_user_id(cc_num):
    """신용카드 번호를 user_id로 변환 (개인정보 보호)"""
    return f"user_{hashlib.md5(str(cc_num).encode()).hexdigest()[:8]}"


def create_merchant_id(merchant):
    """머천트명을 merchant_id로 변환"""
    return f"merch_{hashlib.md5(str(merchant).encode()).hexdigest()[:8]}"


def prepare_transactions(df):
    """거래 이벤트 테이블 생성"""
    print("Preparing transactions table...")

    transactions = pd.DataFrame({
        'transaction_id': df['trans_num'],
        'user_id': df['cc_num'].apply(create_user_id),
        'merchant_id': df['merchant'].apply(create_merchant_id),
        'category': df['category'],
        'amount': df['amt'],
        'is_fraud': df['is_fraud'],
        'event_timestamp': pd.to_datetime(df['trans_date_trans_time']),
        'lat': df['lat'],
        'long': df['long'],
        'merch_lat': df['merch_lat'],
        'merch_long': df['merch_long'],
    })

    return transactions


def prepare_user_demographics(df):
    """사용자 인구통계 테이블 생성"""
    print("Preparing user demographics...")

    # 각 사용자별 첫 거래 시점의 정보 사용
    first_txn = df.sort_values('trans_date_trans_time').groupby('cc_num').first().reset_index()

    demographics = pd.DataFrame({
        'user_id': first_txn['cc_num'].apply(create_user_id),
        'gender': first_txn['gender'],
        'city': first_txn['city'],
        'state': first_txn['state'],
        'zip_code': first_txn['zip'],
        'lat': first_txn['lat'],
        'long': first_txn['long'],
        'city_pop': first_txn['city_pop'],
        'job': first_txn['job'],
        'dob': pd.to_datetime(first_txn['dob']),
        'created_at': pd.to_datetime(first_txn['trans_date_trans_time']),
    })

    # 나이 계산 (첫 거래 시점 기준)
    demographics['age'] = ((demographics['created_at'] - demographics['dob']).dt.days / 365.25).astype(int)

    return demographics


def compute_user_features(df):
    """시간에 따라 변하는 사용자 피처 생성 (Point-in-Time Join용)"""
    print("Computing time-varying user features...")

    df = df.copy()
    df['trans_date_trans_time'] = pd.to_datetime(df['trans_date_trans_time'])
    df['user_id'] = df['cc_num'].apply(create_user_id)
    df = df.sort_values('trans_date_trans_time')

    # 일별로 피처 계산 (매일 업데이트되는 피처)
    df['date'] = df['trans_date_trans_time'].dt.date

    user_features_list = []

    # 각 사용자별로 누적 통계 계산
    for user_id in df['user_id'].unique():
        user_df = df[df['user_id'] == user_id].copy()

        # 날짜별로 그룹화하여 일별 피처 생성
        dates = user_df['date'].unique()

        for i, current_date in enumerate(dates):
            # 현재 날짜까지의 모든 거래
            mask = user_df['date'] <= current_date
            history = user_df[mask]

            # 최근 7일 거래
            week_ago = current_date - timedelta(days=7)
            recent_7d = history[history['date'] > week_ago]

            # 최근 30일 거래
            month_ago = current_date - timedelta(days=30)
            recent_30d = history[history['date'] > month_ago]

            features = {
                'user_id': user_id,
                'total_transactions': len(history),
                'total_amount': history['amt'].sum(),
                'avg_amount': history['amt'].mean(),
                'max_amount': history['amt'].max(),
                'min_amount': history['amt'].min(),
                'std_amount': history['amt'].std() if len(history) > 1 else 0,
                'transactions_7d': len(recent_7d),
                'amount_7d': recent_7d['amt'].sum(),
                'avg_amount_7d': recent_7d['amt'].mean() if len(recent_7d) > 0 else 0,
                'transactions_30d': len(recent_30d),
                'amount_30d': recent_30d['amt'].sum(),
                'avg_amount_30d': recent_30d['amt'].mean() if len(recent_30d) > 0 else 0,
                'unique_merchants': history['merchant'].nunique(),
                'unique_categories': history['category'].nunique(),
                'fraud_count': history['is_fraud'].sum(),
                'created_at': pd.Timestamp(current_date),
            }
            user_features_list.append(features)

    user_features = pd.DataFrame(user_features_list)
    print(f"Generated {len(user_features):,} user feature snapshots")
    return user_features


def prepare_merchant_features(df):
    """머천트 피처 생성"""
    print("Preparing merchant features...")

    df = df.copy()
    df['merchant_id'] = df['merchant'].apply(create_merchant_id)

    merchant_stats = df.groupby('merchant_id').agg({
        'amt': ['mean', 'std', 'min', 'max', 'count'],
        'is_fraud': ['sum', 'mean'],
        'category': 'first',
        'merch_lat': 'first',
        'merch_long': 'first',
        'trans_date_trans_time': 'max',
    }).reset_index()

    merchant_stats.columns = [
        'merchant_id',
        'avg_transaction_amount', 'std_transaction_amount',
        'min_transaction_amount', 'max_transaction_amount',
        'total_transactions',
        'fraud_count', 'fraud_rate',
        'primary_category',
        'lat', 'long',
        'last_transaction_time',
    ]

    merchant_stats['created_at'] = pd.to_datetime(merchant_stats['last_transaction_time'])
    merchant_stats = merchant_stats.drop('last_transaction_time', axis=1)

    return merchant_stats


def prepare_category_features(df):
    """카테고리 피처 생성"""
    print("Preparing category features...")

    category_stats = df.groupby('category').agg({
        'amt': ['mean', 'std', 'min', 'max', 'count'],
        'is_fraud': ['sum', 'mean'],
        'trans_date_trans_time': 'max',
    }).reset_index()

    category_stats.columns = [
        'category',
        'avg_amount', 'std_amount', 'min_amount', 'max_amount',
        'total_transactions',
        'fraud_count', 'fraud_rate',
        'last_transaction_time',
    ]

    category_stats['created_at'] = pd.to_datetime(category_stats['last_transaction_time'])
    category_stats = category_stats.drop('last_transaction_time', axis=1)

    return category_stats


def save_to_csv(data_dict):
    """CSV 파일로 저장"""
    print("\nSaving to CSV...")
    for name, df in data_dict.items():
        path = OUTPUT_DIR / f"{name}.csv"
        df.to_csv(path, index=False)
        print(f"  {name}: {len(df):,} rows -> {path}")


def generate_sql_load_script(data_dict):
    """PostgreSQL 로드용 SQL 스크립트 생성"""
    print("\nGenerating SQL load script...")

    sql_script = """-- Fraud Detection 데이터 로드 스크립트
-- Point-in-Time Join을 위한 Feast Feature Store 데이터
-- 생성일: {date}

SET search_path TO features, public;

-- 기존 테이블 삭제 (있는 경우)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS user_demographics CASCADE;
DROP TABLE IF EXISTS user_features CASCADE;
DROP TABLE IF EXISTS merchant_features CASCADE;
DROP TABLE IF EXISTS category_features CASCADE;

-- 1. 거래 이벤트 테이블 (Entity DataFrame용)
CREATE TABLE transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    merchant_id VARCHAR(20) NOT NULL,
    category VARCHAR(50),
    amount DECIMAL(10,2),
    is_fraud INTEGER,
    event_timestamp TIMESTAMP NOT NULL,
    lat DECIMAL(10,6),
    long DECIMAL(10,6),
    merch_lat DECIMAL(10,6),
    merch_long DECIMAL(10,6)
);

-- 2. 사용자 인구통계 테이블
CREATE TABLE user_demographics (
    user_id VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(1),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code INTEGER,
    lat DECIMAL(10,6),
    long DECIMAL(10,6),
    city_pop INTEGER,
    job VARCHAR(100),
    dob DATE,
    age INTEGER,
    created_at TIMESTAMP NOT NULL
);

-- 3. 사용자 피처 테이블 (시간에 따라 변함 - Point-in-Time Join용)
CREATE TABLE user_features (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    total_transactions INTEGER,
    total_amount DECIMAL(12,2),
    avg_amount DECIMAL(10,2),
    max_amount DECIMAL(10,2),
    min_amount DECIMAL(10,2),
    std_amount DECIMAL(10,2),
    transactions_7d INTEGER,
    amount_7d DECIMAL(12,2),
    avg_amount_7d DECIMAL(10,2),
    transactions_30d INTEGER,
    amount_30d DECIMAL(12,2),
    avg_amount_30d DECIMAL(10,2),
    unique_merchants INTEGER,
    unique_categories INTEGER,
    fraud_count INTEGER,
    created_at TIMESTAMP NOT NULL
);

-- 4. 머천트 피처 테이블
CREATE TABLE merchant_features (
    merchant_id VARCHAR(20) PRIMARY KEY,
    avg_transaction_amount DECIMAL(10,2),
    std_transaction_amount DECIMAL(10,2),
    min_transaction_amount DECIMAL(10,2),
    max_transaction_amount DECIMAL(10,2),
    total_transactions INTEGER,
    fraud_count INTEGER,
    fraud_rate DECIMAL(6,4),
    primary_category VARCHAR(50),
    lat DECIMAL(10,6),
    long DECIMAL(10,6),
    created_at TIMESTAMP NOT NULL
);

-- 5. 카테고리 피처 테이블
CREATE TABLE category_features (
    category VARCHAR(50) PRIMARY KEY,
    avg_amount DECIMAL(10,2),
    std_amount DECIMAL(10,2),
    min_amount DECIMAL(10,2),
    max_amount DECIMAL(10,2),
    total_transactions INTEGER,
    fraud_count INTEGER,
    fraud_rate DECIMAL(6,4),
    created_at TIMESTAMP NOT NULL
);

-- 인덱스 생성 (Point-in-Time Join 성능 최적화)
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_event_timestamp ON transactions(event_timestamp);
CREATE INDEX idx_transactions_user_timestamp ON transactions(user_id, event_timestamp);

CREATE INDEX idx_user_features_user_id ON user_features(user_id);
CREATE INDEX idx_user_features_created_at ON user_features(created_at);
CREATE INDEX idx_user_features_user_created ON user_features(user_id, created_at);

CREATE INDEX idx_merchant_features_created_at ON merchant_features(created_at);
CREATE INDEX idx_category_features_created_at ON category_features(created_at);

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE 'Fraud Detection 테이블 생성 완료';
  RAISE NOTICE 'CSV 파일을 COPY 명령으로 로드하세요';
END $$;
""".format(date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sql_path = OUTPUT_DIR / "create_tables.sql"
    with open(sql_path, 'w') as f:
        f.write(sql_script)
    print(f"  SQL script: {sql_path}")

    return sql_script


def main():
    print("=" * 60)
    print("Fraud Detection 데이터 전처리 시작")
    print("=" * 60)

    # 데이터 로드 및 샘플링
    df = load_and_sample_data()

    # 테이블별 데이터 생성
    transactions = prepare_transactions(df)
    user_demographics = prepare_user_demographics(df)
    user_features = compute_user_features(df)
    merchant_features = prepare_merchant_features(df)
    category_features = prepare_category_features(df)

    data_dict = {
        'transactions': transactions,
        'user_demographics': user_demographics,
        'user_features': user_features,
        'merchant_features': merchant_features,
        'category_features': category_features,
    }

    # CSV 저장
    save_to_csv(data_dict)

    # SQL 스크립트 생성
    generate_sql_load_script(data_dict)

    print("\n" + "=" * 60)
    print("전처리 완료!")
    print("=" * 60)
    print(f"\n출력 디렉토리: {OUTPUT_DIR}")
    print("\n다음 단계:")
    print("1. Docker Compose로 PostgreSQL 시작")
    print("2. create_tables.sql 실행")
    print("3. CSV 파일을 COPY 명령으로 로드")


if __name__ == "__main__":
    main()

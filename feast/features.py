"""
Feast Feature 정의 - Fraud Detection

Point-in-Time Join을 위한 Feature View 정의
- 사용자 피처: 시간에 따라 변하는 거래 통계
- 머천트 피처: 머천트별 거래 특성
- 카테고리 피처: 카테고리별 통계
"""

from feast import Entity, FeatureView, Field
from feast.infra.offline_stores.contrib.postgres_offline_store.postgres_source import (
    PostgreSQLSource,
)
from feast.types import Float64, Int64, String, UnixTimestamp
from datetime import timedelta


# =============================================================================
# Entity 정의
# =============================================================================

user = Entity(
    name="user_id",
    description="사용자 고유 식별자 (익명화된 신용카드 번호)",
)

merchant = Entity(
    name="merchant_id",
    description="머천트 고유 식별자",
)

category = Entity(
    name="category",
    description="거래 카테고리",
)


# =============================================================================
# 데이터 소스 정의
# =============================================================================

# 사용자 인구통계 소스
user_demographics_source = PostgreSQLSource(
    name="user_demographics_source",
    query="""
        SELECT user_id, gender, city, state, zip_code, lat, long,
               city_pop, job, age, created_at
        FROM features.user_demographics
    """,
    timestamp_field="created_at",
)

# 사용자 피처 소스 (시간에 따라 변함)
user_features_source = PostgreSQLSource(
    name="user_features_source",
    query="""
        SELECT user_id, total_transactions, total_amount, avg_amount,
               max_amount, min_amount, std_amount,
               transactions_7d, amount_7d, avg_amount_7d,
               transactions_30d, amount_30d, avg_amount_30d,
               unique_merchants, unique_categories, fraud_count,
               created_at
        FROM features.user_features
    """,
    timestamp_field="created_at",
)

# 머천트 피처 소스
merchant_features_source = PostgreSQLSource(
    name="merchant_features_source",
    query="""
        SELECT merchant_id, avg_transaction_amount, std_transaction_amount,
               min_transaction_amount, max_transaction_amount,
               total_transactions, fraud_count, fraud_rate,
               primary_category, lat, long, created_at
        FROM features.merchant_features
    """,
    timestamp_field="created_at",
)

# 카테고리 피처 소스
category_features_source = PostgreSQLSource(
    name="category_features_source",
    query="""
        SELECT category, avg_amount, std_amount, min_amount, max_amount,
               total_transactions, fraud_count, fraud_rate, created_at
        FROM features.category_features
    """,
    timestamp_field="created_at",
)


# =============================================================================
# Feature View 정의
# =============================================================================

# 사용자 인구통계 피처 (정적, 거의 변하지 않음)
user_demographics_fv = FeatureView(
    name="user_demographics",
    entities=[user],
    ttl=timedelta(days=365),
    schema=[
        Field(name="gender", dtype=String, description="성별"),
        Field(name="city", dtype=String, description="도시"),
        Field(name="state", dtype=String, description="주"),
        Field(name="zip_code", dtype=Int64, description="우편번호"),
        Field(name="lat", dtype=Float64, description="위도"),
        Field(name="long", dtype=Float64, description="경도"),
        Field(name="city_pop", dtype=Int64, description="도시 인구"),
        Field(name="job", dtype=String, description="직업"),
        Field(name="age", dtype=Int64, description="나이"),
    ],
    source=user_demographics_source,
    description="사용자 인구통계 정보 (Point-in-Time Join 지원)",
)

# 사용자 거래 피처 (동적, Point-in-Time Join 핵심)
user_transaction_features_fv = FeatureView(
    name="user_transaction_features",
    entities=[user],
    ttl=timedelta(days=90),
    schema=[
        Field(name="total_transactions", dtype=Int64, description="총 거래 횟수"),
        Field(name="total_amount", dtype=Float64, description="총 거래 금액"),
        Field(name="avg_amount", dtype=Float64, description="평균 거래 금액"),
        Field(name="max_amount", dtype=Float64, description="최대 거래 금액"),
        Field(name="min_amount", dtype=Float64, description="최소 거래 금액"),
        Field(name="std_amount", dtype=Float64, description="거래 금액 표준편차"),
        Field(name="transactions_7d", dtype=Int64, description="최근 7일 거래 횟수"),
        Field(name="amount_7d", dtype=Float64, description="최근 7일 거래 금액"),
        Field(name="avg_amount_7d", dtype=Float64, description="최근 7일 평균 금액"),
        Field(name="transactions_30d", dtype=Int64, description="최근 30일 거래 횟수"),
        Field(name="amount_30d", dtype=Float64, description="최근 30일 거래 금액"),
        Field(name="avg_amount_30d", dtype=Float64, description="최근 30일 평균 금액"),
        Field(name="unique_merchants", dtype=Int64, description="고유 머천트 수"),
        Field(name="unique_categories", dtype=Int64, description="고유 카테고리 수"),
        Field(name="fraud_count", dtype=Int64, description="과거 사기 횟수"),
    ],
    source=user_features_source,
    description="사용자 거래 통계 피처 (시간에 따라 변함, Point-in-Time Join용)",
)

# 머천트 피처
merchant_features_fv = FeatureView(
    name="merchant_features",
    entities=[merchant],
    ttl=timedelta(days=30),
    schema=[
        Field(name="avg_transaction_amount", dtype=Float64, description="평균 거래 금액"),
        Field(name="std_transaction_amount", dtype=Float64, description="거래 금액 표준편차"),
        Field(name="min_transaction_amount", dtype=Float64, description="최소 거래 금액"),
        Field(name="max_transaction_amount", dtype=Float64, description="최대 거래 금액"),
        Field(name="total_transactions", dtype=Int64, description="총 거래 횟수"),
        Field(name="fraud_count", dtype=Int64, description="사기 횟수"),
        Field(name="fraud_rate", dtype=Float64, description="사기 비율"),
        Field(name="primary_category", dtype=String, description="주요 카테고리"),
        Field(name="lat", dtype=Float64, description="머천트 위도"),
        Field(name="long", dtype=Float64, description="머천트 경도"),
    ],
    source=merchant_features_source,
    description="머천트 거래 특성 피처",
)

# 카테고리 피처
category_features_fv = FeatureView(
    name="category_features",
    entities=[category],
    ttl=timedelta(days=30),
    schema=[
        Field(name="avg_amount", dtype=Float64, description="카테고리 평균 금액"),
        Field(name="std_amount", dtype=Float64, description="카테고리 금액 표준편차"),
        Field(name="min_amount", dtype=Float64, description="카테고리 최소 금액"),
        Field(name="max_amount", dtype=Float64, description="카테고리 최대 금액"),
        Field(name="total_transactions", dtype=Int64, description="카테고리 총 거래 수"),
        Field(name="fraud_count", dtype=Int64, description="카테고리 사기 횟수"),
        Field(name="fraud_rate", dtype=Float64, description="카테고리 사기 비율"),
    ],
    source=category_features_source,
    description="카테고리별 거래 통계 피처",
)

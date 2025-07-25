from feast import Entity, FeatureView, Field, ValueType
from feast.infra.offline_stores.contrib.postgres_offline_store.postgres_source import (
    PostgreSQLSource,
)
from feast.types import Float32, Int64, String
from datetime import timedelta

# 엔티티 정의
user = Entity(
    name="user_id",
    value_type=ValueType.STRING,
    description="사용자 고유 식별자",
)

product = Entity(
    name="product_id", 
    value_type=ValueType.STRING,
    description="상품 고유 식별자",
)

session = Entity(
    name="session_id",
    value_type=ValueType.STRING,
    description="세션 고유 식별자",
)

# 데이터 소스 정의
user_demographics_source = PostgreSQLSource(
    name="user_demographics_source",
    query="SELECT user_id, age, country_code, created_at FROM features.user_demographics",
    timestamp_field="created_at",
    description="사용자 기본 정보 데이터 소스",
)

user_purchase_summary_source = PostgreSQLSource(
    name="user_purchase_summary_source",
    query="SELECT user_id, ltv, total_purchase_count, last_purchase_date, created_at FROM features.user_purchase_summary",
    timestamp_field="created_at",
    description="사용자 구매 요약 데이터 소스",
)

product_details_source = PostgreSQLSource(
    name="product_details_source",
    query="SELECT product_id, price, category, brand, created_at FROM features.product_details",
    timestamp_field="created_at",
    description="상품 상세 정보 데이터 소스",
)

session_summary_source = PostgreSQLSource(
    name="session_summary_source",
    query="SELECT session_id, time_on_page_seconds, click_count, created_at FROM features.session_summary",
    timestamp_field="created_at",
    description="세션 요약 데이터 소스",
)

# 피처 뷰 정의
user_demographics_fv = FeatureView(
    name="user_demographics",
    entities=[user],
    ttl=timedelta(days=365),
    schema=[
        Field(name="age", dtype=Int64),
        Field(name="country_code", dtype=String),
    ],
    source=user_demographics_source,
    description="사용자 기본 정보 피처 뷰",
)

user_purchase_summary_fv = FeatureView(
    name="user_purchase_summary",
    entities=[user],
    ttl=timedelta(days=90),
    schema=[
        Field(name="ltv", dtype=Float32),
        Field(name="total_purchase_count", dtype=Int64),
        Field(name="last_purchase_date", dtype=Int64), # Unix Timestamp
    ],
    source=user_purchase_summary_source,
    description="사용자 구매 요약 피처 뷰",
)

product_details_fv = FeatureView(
    name="product_details",
    entities=[product],
    ttl=timedelta(days=30),
    schema=[
        Field(name="price", dtype=Float32),
        Field(name="category", dtype=String),
        Field(name="brand", dtype=String),
    ],
    source=product_details_source,
    description="상품 상세 정보 피처 뷰",
)

session_summary_fv = FeatureView(
    name="session_summary",
    entities=[session],
    ttl=timedelta(days=7),
    schema=[
        Field(name="time_on_page_seconds", dtype=Int64),
        Field(name="click_count", dtype=Int64),
    ],
    source=session_summary_source,
    description="세션 요약 피처 뷰",
) 
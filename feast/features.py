from feast import Entity, FeatureView, Field
from feast.data_source import DataSource
from feast.infra.offline_stores.postgres import PostgreSQLSource
from feast.types import Float64, Int64, String, UnixTimestamp
from datetime import timedelta

# 엔티티 정의
user = Entity(
    name="user_id",
    value_type=String,
    description="사용자 고유 식별자",
)

product = Entity(
    name="product_id", 
    value_type=String,
    description="상품 고유 식별자",
)

session = Entity(
    name="session_id",
    value_type=String,
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
    ttl=timedelta(days=365),  # 1년간 유효
    schema=[
        Field(name="age", dtype=Int64, description="사용자 나이"),
        Field(name="country_code", dtype=String, description="국가 코드"),
    ],
    source=user_demographics_source,
    description="사용자 기본 정보 피처 뷰",
)

user_purchase_summary_fv = FeatureView(
    name="user_purchase_summary",
    entities=[user],
    ttl=timedelta(days=90),  # 90일간 유효
    schema=[
        Field(name="ltv", dtype=Float64, description="고객 생애 가치"),
        Field(name="total_purchase_count", dtype=Int64, description="총 구매 횟수"),
        Field(name="last_purchase_date", dtype=UnixTimestamp, description="마지막 구매일"),
    ],
    source=user_purchase_summary_source,
    description="사용자 구매 요약 피처 뷰",
)

product_details_fv = FeatureView(
    name="product_details",
    entities=[product],
    ttl=timedelta(days=30),  # 30일간 유효
    schema=[
        Field(name="price", dtype=Float64, description="상품 가격"),
        Field(name="category", dtype=String, description="상품 카테고리"),
        Field(name="brand", dtype=String, description="상품 브랜드"),
    ],
    source=product_details_source,
    description="상품 상세 정보 피처 뷰",
)

session_summary_fv = FeatureView(
    name="session_summary",
    entities=[session],
    ttl=timedelta(days=7),  # 7일간 유효
    schema=[
        Field(name="time_on_page_seconds", dtype=Int64, description="페이지 체류 시간(초)"),
        Field(name="click_count", dtype=Int64, description="클릭 횟수"),
    ],
    source=session_summary_source,
    description="세션 요약 피처 뷰",
) 
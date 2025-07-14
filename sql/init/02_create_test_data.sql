-- 테스트 데이터 생성
-- Blueprint v17.0: Feature Store 네임스페이스 구조

-- ===========================================
-- 1. Raw Data Tables (Spine 생성용)
-- ===========================================

-- 사용자 Spine 데이터 
CREATE TABLE IF NOT EXISTS spine_data.user_spine (
    user_id VARCHAR(50) PRIMARY KEY,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 상품 Spine 데이터
CREATE TABLE IF NOT EXISTS spine_data.product_spine (
    product_id VARCHAR(50) PRIMARY KEY,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 세션 Spine 데이터
CREATE TABLE IF NOT EXISTS spine_data.session_spine (
    session_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    product_id VARCHAR(50),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===========================================
-- 2. Feature Store Tables (Blueprint 네임스페이스)
-- ===========================================

-- user_demographics 네임스페이스
CREATE TABLE IF NOT EXISTS feature_mart.user_demographics (
    user_id VARCHAR(50) PRIMARY KEY,
    age INTEGER,
    country_code VARCHAR(5),
    gender VARCHAR(10),
    education_level VARCHAR(50),
    income_bracket VARCHAR(20),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- user_purchase_summary 네임스페이스  
CREATE TABLE IF NOT EXISTS feature_mart.user_purchase_summary (
    user_id VARCHAR(50) PRIMARY KEY,
    ltv DECIMAL(10,2),
    total_purchase_count INTEGER,
    avg_order_value DECIMAL(10,2),
    last_purchase_days_ago INTEGER,
    preferred_category VARCHAR(100),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- product_details 네임스페이스
CREATE TABLE IF NOT EXISTS feature_mart.product_details (
    product_id VARCHAR(50) PRIMARY KEY,
    price DECIMAL(10,2),
    category VARCHAR(100),
    brand VARCHAR(100),
    avg_rating DECIMAL(3,2),
    review_count INTEGER,
    discount_rate DECIMAL(5,2),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- session_summary 네임스페이스
CREATE TABLE IF NOT EXISTS feature_mart.session_summary (
    session_id VARCHAR(50) PRIMARY KEY,
    time_on_page_seconds INTEGER,
    click_count INTEGER,
    page_views INTEGER,
    bounce_rate DECIMAL(5,2),
    conversion_score DECIMAL(5,2),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===========================================
-- 3. Sample Data Insertion 
-- ===========================================

-- Spine 데이터 삽입
INSERT INTO spine_data.user_spine (user_id, event_timestamp) VALUES
('user_001', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('user_002', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('user_003', CURRENT_TIMESTAMP - INTERVAL '3 days'),
('user_004', CURRENT_TIMESTAMP - INTERVAL '4 days'),
('user_005', CURRENT_TIMESTAMP - INTERVAL '5 days')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO spine_data.product_spine (product_id, event_timestamp) VALUES
('prod_001', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('prod_002', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('prod_003', CURRENT_TIMESTAMP - INTERVAL '3 days'),
('prod_004', CURRENT_TIMESTAMP - INTERVAL '4 days'),
('prod_005', CURRENT_TIMESTAMP - INTERVAL '5 days')
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO spine_data.session_spine (session_id, user_id, product_id, event_timestamp) VALUES
('sess_001', 'user_001', 'prod_001', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('sess_002', 'user_002', 'prod_002', CURRENT_TIMESTAMP - INTERVAL '2 days'),
('sess_003', 'user_003', 'prod_003', CURRENT_TIMESTAMP - INTERVAL '3 days'),
('sess_004', 'user_004', 'prod_004', CURRENT_TIMESTAMP - INTERVAL '4 days'),
('sess_005', 'user_005', 'prod_005', CURRENT_TIMESTAMP - INTERVAL '5 days')
ON CONFLICT (session_id) DO NOTHING;

-- Feature Store 데이터 삽입
INSERT INTO feature_mart.user_demographics (user_id, age, country_code, gender, education_level, income_bracket) VALUES
('user_001', 25, 'KR', 'M', 'Bachelor', '50-75K'),
('user_002', 34, 'US', 'F', 'Master', '75-100K'),
('user_003', 28, 'JP', 'M', 'Bachelor', '50-75K'),
('user_004', 42, 'KR', 'F', 'PhD', '100K+'),
('user_005', 31, 'US', 'M', 'Master', '75-100K')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO feature_mart.user_purchase_summary (user_id, ltv, total_purchase_count, avg_order_value, last_purchase_days_ago, preferred_category) VALUES
('user_001', 1250.50, 15, 83.37, 5, 'Electronics'),
('user_002', 2100.75, 28, 75.03, 2, 'Clothing'),
('user_003', 890.25, 12, 74.19, 7, 'Home'),
('user_004', 3200.00, 45, 71.11, 1, 'Books'),
('user_005', 1750.80, 22, 79.58, 3, 'Electronics')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO feature_mart.product_details (product_id, price, category, brand, avg_rating, review_count, discount_rate) VALUES
('prod_001', 29.99, 'Electronics', 'BrandA', 4.5, 1250, 10.0),
('prod_002', 89.99, 'Clothing', 'BrandB', 4.2, 890, 15.0),
('prod_003', 149.99, 'Home', 'BrandC', 4.7, 2100, 5.0),
('prod_004', 19.99, 'Books', 'BrandD', 4.1, 650, 20.0),
('prod_005', 199.99, 'Electronics', 'BrandA', 4.8, 1800, 8.0)
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO feature_mart.session_summary (session_id, time_on_page_seconds, click_count, page_views, bounce_rate, conversion_score) VALUES
('sess_001', 180, 5, 8, 25.5, 0.75),
('sess_002', 245, 8, 12, 15.2, 0.85),
('sess_003', 120, 3, 5, 45.8, 0.45),
('sess_004', 310, 12, 18, 8.9, 0.92),
('sess_005', 195, 7, 10, 22.1, 0.68)
ON CONFLICT (session_id) DO NOTHING; 
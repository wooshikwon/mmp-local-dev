-- Feature Store 피처 테이블 및 샘플 데이터 생성 스크립트
-- ML Pipeline Local Development Environment

-- Set working schema
SET search_path TO features, public;

-- 1. 사용자 기본 정보 피처 테이블
CREATE TABLE IF NOT EXISTS user_demographics (
    user_id VARCHAR(50) PRIMARY KEY,
    age INTEGER,
    country_code VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 사용자 구매 요약 피처 테이블
CREATE TABLE IF NOT EXISTS user_purchase_summary (
    user_id VARCHAR(50) PRIMARY KEY,
    ltv DECIMAL(10,2),
    total_purchase_count INTEGER,
    last_purchase_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 상품 상세 정보 피처 테이블
CREATE TABLE IF NOT EXISTS product_details (
    product_id VARCHAR(50) PRIMARY KEY,
    price DECIMAL(10,2),
    category VARCHAR(100),
    brand VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. 세션 요약 피처 테이블
CREATE TABLE IF NOT EXISTS session_summary (
    session_id VARCHAR(50) PRIMARY KEY,
    time_on_page_seconds INTEGER,
    click_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 샘플 데이터 삽입

-- 사용자 기본 정보 (100개 사용자)
INSERT INTO user_demographics (user_id, age, country_code) VALUES
('user_001', 25, 'US'), ('user_002', 32, 'KR'), ('user_003', 28, 'JP'),
('user_004', 35, 'GB'), ('user_005', 29, 'DE'), ('user_006', 42, 'FR'),
('user_007', 31, 'CA'), ('user_008', 27, 'AU'), ('user_009', 38, 'IT'),
('user_010', 33, 'ES'), ('user_011', 26, 'BR'), ('user_012', 41, 'MX'),
('user_013', 34, 'IN'), ('user_014', 30, 'CN'), ('user_015', 37, 'RU'),
('user_016', 24, 'NL'), ('user_017', 39, 'SE'), ('user_018', 28, 'NO'),
('user_019', 36, 'DK'), ('user_020', 31, 'FI'), ('user_021', 29, 'CH'),
('user_022', 43, 'AT'), ('user_023', 32, 'BE'), ('user_024', 27, 'PL'),
('user_025', 40, 'CZ'), ('user_026', 33, 'HU'), ('user_027', 26, 'PT'),
('user_028', 35, 'GR'), ('user_029', 31, 'IE'), ('user_030', 28, 'NZ'),
('user_031', 37, 'SG'), ('user_032', 29, 'HK'), ('user_033', 34, 'TW'),
('user_034', 41, 'TH'), ('user_035', 30, 'MY'), ('user_036', 25, 'PH'),
('user_037', 38, 'VN'), ('user_038', 32, 'ID'), ('user_039', 27, 'SA'),
('user_040', 36, 'AE'), ('user_041', 33, 'IL'), ('user_042', 29, 'TR'),
('user_043', 42, 'ZA'), ('user_044', 31, 'EG'), ('user_045', 28, 'NG'),
('user_046', 35, 'KE'), ('user_047', 26, 'GH'), ('user_048', 39, 'MA'),
('user_049', 34, 'TN'), ('user_050', 30, 'DZ'), ('user_051', 37, 'LY'),
('user_052', 32, 'JO'), ('user_053', 28, 'LB'), ('user_054', 41, 'SY'),
('user_055', 29, 'IQ'), ('user_056', 36, 'IR'), ('user_057', 33, 'AF'),
('user_058', 27, 'PK'), ('user_059', 40, 'BD'), ('user_060', 31, 'LK'),
('user_061', 35, 'MM'), ('user_062', 28, 'KH'), ('user_063', 38, 'LA'),
('user_064', 32, 'NP'), ('user_065', 26, 'BT'), ('user_066', 43, 'MV'),
('user_067', 34, 'MN'), ('user_068', 30, 'KZ'), ('user_069', 37, 'UZ'),
('user_070', 29, 'KG'), ('user_071', 41, 'TJ'), ('user_072', 33, 'TM'),
('user_073', 27, 'AZ'), ('user_074', 36, 'AM'), ('user_075', 31, 'GE'),
('user_076', 28, 'MD'), ('user_077', 39, 'UA'), ('user_078', 35, 'BY'),
('user_079', 32, 'LT'), ('user_080', 26, 'LV'), ('user_081', 42, 'EE'),
('user_082', 34, 'SK'), ('user_083', 30, 'SI'), ('user_084', 37, 'HR'),
('user_085', 29, 'BA'), ('user_086', 41, 'RS'), ('user_087', 33, 'ME'),
('user_088', 27, 'MK'), ('user_089', 36, 'AL'), ('user_090', 31, 'BG'),
('user_091', 28, 'RO'), ('user_092', 38, 'CY'), ('user_093', 32, 'MT'),
('user_094', 25, 'LU'), ('user_095', 40, 'MC'), ('user_096', 34, 'AD'),
('user_097', 30, 'SM'), ('user_098', 37, 'VA'), ('user_099', 29, 'LI'),
('user_100', 35, 'IS');

-- 사용자 구매 요약 (100개 사용자)
INSERT INTO user_purchase_summary (user_id, ltv, total_purchase_count, last_purchase_date) VALUES
('user_001', 1250.50, 15, '2024-01-15'), ('user_002', 2340.75, 28, '2024-01-20'),
('user_003', 890.25, 12, '2024-01-10'), ('user_004', 3200.00, 45, '2024-01-25'),
('user_005', 1780.30, 22, '2024-01-18'), ('user_006', 980.50, 8, '2024-01-12'),
('user_007', 2150.75, 31, '2024-01-22'), ('user_008', 1540.20, 19, '2024-01-16'),
('user_009', 2890.40, 38, '2024-01-24'), ('user_010', 1320.60, 16, '2024-01-14'),
('user_011', 870.30, 11, '2024-01-08'), ('user_012', 1680.90, 21, '2024-01-19'),
('user_013', 2420.15, 33, '2024-01-23'), ('user_014', 1890.75, 25, '2024-01-17'),
('user_015', 3450.20, 52, '2024-01-26'), ('user_016', 750.40, 9, '2024-01-11'),
('user_017', 1960.80, 27, '2024-01-21'), ('user_018', 1240.50, 14, '2024-01-13'),
('user_019', 2680.30, 36, '2024-01-24'), ('user_020', 1450.70, 18, '2024-01-15'),
('user_021', 1120.25, 13, '2024-01-09'), ('user_022', 2790.85, 39, '2024-01-25'),
('user_023', 1380.40, 17, '2024-01-16'), ('user_024', 920.60, 10, '2024-01-07'),
('user_025', 2560.90, 34, '2024-01-23'), ('user_026', 1780.30, 23, '2024-01-18'),
('user_027', 1050.70, 12, '2024-01-10'), ('user_028', 2330.20, 30, '2024-01-22'),
('user_029', 1640.85, 20, '2024-01-17'), ('user_030', 890.45, 11, '2024-01-08'),
('user_031', 1890.60, 26, '2024-01-20'), ('user_032', 2140.75, 29, '2024-01-21'),
('user_033', 1560.30, 19, '2024-01-16'), ('user_034', 2750.40, 37, '2024-01-24'),
('user_035', 1320.90, 15, '2024-01-14'), ('user_036', 780.25, 8, '2024-01-06'),
('user_037', 2480.60, 32, '2024-01-23'), ('user_038', 1750.80, 24, '2024-01-19'),
('user_039', 1180.35, 13, '2024-01-12'), ('user_040', 2890.50, 41, '2024-01-25'),
('user_041', 1460.70, 18, '2024-01-15'), ('user_042', 990.40, 10, '2024-01-09'),
('user_043', 2670.25, 35, '2024-01-24'), ('user_044', 1590.85, 21, '2024-01-17'),
('user_045', 820.60, 9, '2024-01-07'), ('user_046', 2120.90, 28, '2024-01-21'),
('user_047', 1380.30, 16, '2024-01-14'), ('user_048', 2540.75, 33, '2024-01-23'),
('user_049', 1720.40, 22, '2024-01-18'), ('user_050', 1090.20, 12, '2024-01-11'),
('user_051', 2390.85, 31, '2024-01-22'), ('user_052', 1450.60, 17, '2024-01-15'),
('user_053', 940.30, 11, '2024-01-08'), ('user_054', 2810.70, 40, '2024-01-25'),
('user_055', 1680.45, 23, '2024-01-19'), ('user_056', 1250.90, 14, '2024-01-13'),
('user_057', 2460.25, 34, '2024-01-23'), ('user_058', 1590.80, 20, '2024-01-17'),
('user_059', 870.35, 10, '2024-01-09'), ('user_060', 2180.60, 29, '2024-01-21'),
('user_061', 1420.75, 18, '2024-01-16'), ('user_062', 1080.40, 13, '2024-01-12'),
('user_063', 2650.90, 36, '2024-01-24'), ('user_064', 1540.25, 19, '2024-01-16'),
('user_065', 760.80, 8, '2024-01-06'), ('user_066', 2970.60, 43, '2024-01-26'),
('user_067', 1780.35, 25, '2024-01-20'), ('user_068', 1340.70, 15, '2024-01-14'),
('user_069', 2520.45, 32, '2024-01-22'), ('user_070', 1690.90, 21, '2024-01-18'),
('user_071', 1160.25, 14, '2024-01-13'), ('user_072', 2830.80, 38, '2024-01-25'),
('user_073', 1480.60, 17, '2024-01-15'), ('user_074', 920.35, 11, '2024-01-10'),
('user_075', 2710.70, 37, '2024-01-24'), ('user_076', 1620.45, 20, '2024-01-17'),
('user_077', 1050.90, 12, '2024-01-11'), ('user_078', 2380.25, 30, '2024-01-22'),
('user_079', 1560.80, 19, '2024-01-16'), ('user_080', 890.60, 10, '2024-01-08'),
('user_081', 2190.35, 28, '2024-01-21'), ('user_082', 1390.70, 16, '2024-01-14'),
('user_083', 1120.45, 13, '2024-01-12'), ('user_084', 2680.90, 35, '2024-01-24'),
('user_085', 1750.25, 22, '2024-01-19'), ('user_086', 1280.80, 15, '2024-01-13'),
('user_087', 2500.60, 33, '2024-01-23'), ('user_088', 1640.35, 21, '2024-01-18'),
('user_089', 980.70, 11, '2024-01-09'), ('user_090', 2790.45, 39, '2024-01-25'),
('user_091', 1520.90, 18, '2024-01-16'), ('user_092', 1210.25, 14, '2024-01-12'),
('user_093', 2450.80, 31, '2024-01-22'), ('user_094', 1680.60, 23, '2024-01-19'),
('user_095', 1090.35, 12, '2024-01-10'), ('user_096', 2860.70, 41, '2024-01-26'),
('user_097', 1460.45, 17, '2024-01-15'), ('user_098', 840.90, 9, '2024-01-07'),
('user_099', 2620.25, 34, '2024-01-23'), ('user_100', 1590.80, 20, '2024-01-17');

-- 상품 상세 정보 (50개 상품)
INSERT INTO product_details (product_id, price, category, brand) VALUES
('prod_001', 29.99, 'Electronics', 'TechCorp'), ('prod_002', 149.99, 'Clothing', 'FashionBrand'),
('prod_003', 79.99, 'Home & Garden', 'HomeStyle'), ('prod_004', 199.99, 'Electronics', 'GadgetPro'),
('prod_005', 39.99, 'Books', 'BookWorld'), ('prod_006', 89.99, 'Sports', 'SportMax'),
('prod_007', 59.99, 'Beauty', 'BeautyPlus'), ('prod_008', 129.99, 'Electronics', 'TechCorp'),
('prod_009', 24.99, 'Clothing', 'StyleCo'), ('prod_010', 179.99, 'Home & Garden', 'HomeStyle'),
('prod_011', 99.99, 'Electronics', 'GadgetPro'), ('prod_012', 19.99, 'Books', 'ReadMore'),
('prod_013', 169.99, 'Sports', 'SportMax'), ('prod_014', 49.99, 'Beauty', 'GlowUp'),
('prod_015', 299.99, 'Electronics', 'TechCorp'), ('prod_016', 69.99, 'Clothing', 'FashionBrand'),
('prod_017', 119.99, 'Home & Garden', 'CozyHome'), ('prod_018', 89.99, 'Electronics', 'GadgetPro'),
('prod_019', 34.99, 'Books', 'BookWorld'), ('prod_020', 139.99, 'Sports', 'FitLife'),
('prod_021', 44.99, 'Beauty', 'BeautyPlus'), ('prod_022', 189.99, 'Electronics', 'TechCorp'),
('prod_023', 54.99, 'Clothing', 'StyleCo'), ('prod_024', 229.99, 'Home & Garden', 'HomeStyle'),
('prod_025', 79.99, 'Electronics', 'SmartTech'), ('prod_026', 29.99, 'Books', 'ReadMore'),
('prod_027', 159.99, 'Sports', 'SportMax'), ('prod_028', 39.99, 'Beauty', 'GlowUp'),
('prod_029', 249.99, 'Electronics', 'TechCorp'), ('prod_030', 94.99, 'Clothing', 'FashionBrand'),
('prod_031', 149.99, 'Home & Garden', 'CozyHome'), ('prod_032', 109.99, 'Electronics', 'GadgetPro'),
('prod_033', 24.99, 'Books', 'BookWorld'), ('prod_034', 179.99, 'Sports', 'FitLife'),
('prod_035', 64.99, 'Beauty', 'BeautyPlus'), ('prod_036', 219.99, 'Electronics', 'TechCorp'),
('prod_037', 74.99, 'Clothing', 'StyleCo'), ('prod_038', 199.99, 'Home & Garden', 'HomeStyle'),
('prod_039', 129.99, 'Electronics', 'SmartTech'), ('prod_040', 44.99, 'Books', 'ReadMore'),
('prod_041', 189.99, 'Sports', 'SportMax'), ('prod_042', 54.99, 'Beauty', 'GlowUp'),
('prod_043', 269.99, 'Electronics', 'TechCorp'), ('prod_044', 84.99, 'Clothing', 'FashionBrand'),
('prod_045', 139.99, 'Home & Garden', 'CozyHome'), ('prod_046', 99.99, 'Electronics', 'GadgetPro'),
('prod_047', 19.99, 'Books', 'BookWorld'), ('prod_048', 169.99, 'Sports', 'FitLife'),
('prod_049', 49.99, 'Beauty', 'BeautyPlus'), ('prod_050', 299.99, 'Electronics', 'TechCorp');

-- 세션 요약 (200개 세션)
INSERT INTO session_summary (session_id, time_on_page_seconds, click_count) VALUES
('sess_001', 120, 15), ('sess_002', 340, 28), ('sess_003', 89, 12), ('sess_004', 520, 45),
('sess_005', 278, 22), ('sess_006', 98, 8), ('sess_007', 415, 31), ('sess_008', 254, 19),
('sess_009', 489, 38), ('sess_010', 132, 16), ('sess_011', 87, 11), ('sess_012', 268, 21),
('sess_013', 442, 33), ('sess_014', 289, 25), ('sess_015', 652, 52), ('sess_016', 75, 9),
('sess_017', 396, 27), ('sess_018', 124, 14), ('sess_019', 568, 36), ('sess_020', 245, 18),
('sess_021', 112, 13), ('sess_022', 579, 39), ('sess_023', 238, 17), ('sess_024', 92, 10),
('sess_025', 456, 34), ('sess_026', 378, 23), ('sess_027', 105, 12), ('sess_028', 433, 30),
('sess_029', 264, 20), ('sess_030', 89, 11), ('sess_031', 389, 26), ('sess_032', 414, 29),
('sess_033', 256, 19), ('sess_034', 575, 37), ('sess_035', 232, 15), ('sess_036', 78, 8),
('sess_037', 548, 32), ('sess_038', 375, 24), ('sess_039', 218, 13), ('sess_040', 689, 41),
('sess_041', 246, 18), ('sess_042', 99, 10), ('sess_043', 567, 35), ('sess_044', 259, 21),
('sess_045', 82, 9), ('sess_046', 412, 28), ('sess_047', 238, 16), ('sess_048', 554, 33),
('sess_049', 372, 22), ('sess_050', 109, 12), ('sess_051', 439, 31), ('sess_052', 245, 17),
('sess_053', 94, 11), ('sess_054', 681, 40), ('sess_055', 268, 23), ('sess_056', 125, 14),
('sess_057', 546, 34), ('sess_058', 259, 20), ('sess_059', 87, 10), ('sess_060', 418, 29),
('sess_061', 242, 18), ('sess_062', 108, 13), ('sess_063', 565, 36), ('sess_064', 254, 19),
('sess_065', 76, 8), ('sess_066', 697, 43), ('sess_067', 378, 25), ('sess_068', 134, 15),
('sess_069', 552, 32), ('sess_070', 269, 21), ('sess_071', 116, 14), ('sess_072', 683, 38),
('sess_073', 248, 17), ('sess_074', 92, 11), ('sess_075', 671, 37), ('sess_076', 262, 20),
('sess_077', 105, 12), ('sess_078', 438, 30), ('sess_079', 256, 19), ('sess_080', 89, 10),
('sess_081', 419, 28), ('sess_082', 239, 16), ('sess_083', 112, 13), ('sess_084', 568, 35),
('sess_085', 275, 22), ('sess_086', 128, 15), ('sess_087', 550, 33), ('sess_088', 264, 21),
('sess_089', 98, 11), ('sess_090', 679, 39), ('sess_091', 252, 18), ('sess_092', 121, 14),
('sess_093', 545, 31), ('sess_094', 268, 23), ('sess_095', 109, 12), ('sess_096', 686, 41),
('sess_097', 246, 17), ('sess_098', 84, 9), ('sess_099', 562, 34), ('sess_100', 259, 20),
('sess_101', 145, 16), ('sess_102', 389, 24), ('sess_103', 167, 18), ('sess_104', 445, 31),
('sess_105', 223, 19), ('sess_106', 98, 11), ('sess_107', 534, 29), ('sess_108', 287, 22),
('sess_109', 156, 15), ('sess_110', 612, 38), ('sess_111', 234, 17), ('sess_112', 89, 10),
('sess_113', 478, 33), ('sess_114', 345, 26), ('sess_115', 178, 14), ('sess_116', 567, 35),
('sess_117', 298, 23), ('sess_118', 123, 13), ('sess_119', 645, 40), ('sess_120', 267, 21),
('sess_121', 134, 12), ('sess_122', 523, 32), ('sess_123', 356, 25), ('sess_124', 189, 16),
('sess_125', 612, 39), ('sess_126', 245, 18), ('sess_127', 98, 9), ('sess_128', 578, 34),
('sess_129', 323, 24), ('sess_130', 167, 15), ('sess_131', 489, 30), ('sess_132', 278, 20),
('sess_133', 145, 14), ('sess_134', 634, 37), ('sess_135', 256, 19), ('sess_136', 112, 11),
('sess_137', 567, 35), ('sess_138', 334, 23), ('sess_139', 178, 16), ('sess_140', 623, 38),
('sess_141', 289, 21), ('sess_142', 134, 13), ('sess_143', 545, 31), ('sess_144', 367, 26),
('sess_145', 189, 17), ('sess_146', 656, 41), ('sess_147', 298, 22), ('sess_148', 123, 12),
('sess_149', 578, 36), ('sess_150', 345, 25), ('sess_151', 167, 14), ('sess_152', 612, 39),
('sess_153', 234, 18), ('sess_154', 98, 10), ('sess_155', 534, 33), ('sess_156', 356, 24),
('sess_157', 178, 15), ('sess_158', 645, 40), ('sess_159', 267, 19), ('sess_160', 134, 13),
('sess_161', 523, 32), ('sess_162', 298, 21), ('sess_163', 189, 16), ('sess_164', 612, 38),
('sess_165', 245, 18), ('sess_166', 98, 9), ('sess_167', 578, 34), ('sess_168', 323, 23),
('sess_169', 167, 14), ('sess_170', 489, 30), ('sess_171', 278, 20), ('sess_172', 145, 13),
('sess_173', 634, 37), ('sess_174', 256, 19), ('sess_175', 112, 11), ('sess_176', 567, 35),
('sess_177', 334, 24), ('sess_178', 178, 16), ('sess_179', 623, 38), ('sess_180', 289, 21),
('sess_181', 134, 12), ('sess_182', 545, 31), ('sess_183', 367, 26), ('sess_184', 189, 17),
('sess_185', 656, 41), ('sess_186', 298, 22), ('sess_187', 123, 13), ('sess_188', 578, 36),
('sess_189', 345, 25), ('sess_190', 167, 14), ('sess_191', 612, 39), ('sess_192', 234, 18),
('sess_193', 98, 10), ('sess_194', 534, 33), ('sess_195', 356, 24), ('sess_196', 178, 15),
('sess_197', 645, 40), ('sess_198', 267, 19), ('sess_199', 134, 13), ('sess_200', 523, 32);

-- 성능 최적화를 위한 인덱스 생성
CREATE INDEX idx_user_demographics_created_at ON user_demographics(created_at);
CREATE INDEX idx_user_purchase_summary_created_at ON user_purchase_summary(created_at);
CREATE INDEX idx_user_purchase_summary_last_purchase_date ON user_purchase_summary(last_purchase_date);
CREATE INDEX idx_product_details_created_at ON product_details(created_at);
CREATE INDEX idx_product_details_category ON product_details(category);
CREATE INDEX idx_product_details_brand ON product_details(brand);
CREATE INDEX idx_session_summary_created_at ON session_summary(created_at);

-- 통계 정보 업데이트
ANALYZE user_demographics;
ANALYZE user_purchase_summary;
ANALYZE product_details;
ANALYZE session_summary;

-- 성공적인 시딩 로그
DO $$
BEGIN
  RAISE NOTICE 'Feature Store 샘플 데이터 생성 완료:';
  RAISE NOTICE '- user_demographics: 100개 레코드';
  RAISE NOTICE '- user_purchase_summary: 100개 레코드';
  RAISE NOTICE '- product_details: 50개 레코드';
  RAISE NOTICE '- session_summary: 200개 레코드';
  RAISE NOTICE '- 성능 최적화 인덱스 생성 완료';
END $$; 
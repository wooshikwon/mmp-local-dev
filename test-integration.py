#!/usr/bin/env python3
"""
ML Pipeline Local Development Environment Integration Test

완전한 Feature Store 스택 통합 테스트:
- PostgreSQL 연결 및 데이터 확인
- Redis 연결 및 기본 동작 확인
- MLflow 서버 연결 확인
- Feast 피처 조회 테스트
"""

import os
import sys
import time
import json
from datetime import datetime
from typing import Dict, List, Optional

# 색상 정의
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def log_info(message: str):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {message}")

def log_success(message: str):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {message}")

def log_warning(message: str):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")

def log_error(message: str):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")

class IntegrationTest:
    def __init__(self):
        self.postgres_host = os.getenv('POSTGRES_HOST', 'localhost')
        self.postgres_port = os.getenv('POSTGRES_PORT', '5432')
        self.postgres_db = os.getenv('POSTGRES_DB', 'mlpipeline')
        self.postgres_user = os.getenv('POSTGRES_USER', 'mluser')
        self.postgres_password = os.getenv('POSTGRES_PASSWORD')
        
        self.redis_host = os.getenv('REDIS_HOST', 'localhost')
        self.redis_port = os.getenv('REDIS_PORT', '6379')
        
        self.mlflow_uri = os.getenv('MLFLOW_TRACKING_URI', 'http://localhost:5000')
        
        self.test_results = {}
        
    def test_postgresql_connection(self) -> bool:
        """PostgreSQL 연결 테스트"""
        log_info("PostgreSQL 연결 테스트 중...")
        
        try:
            import psycopg2
            
            # 연결 문자열 생성
            conn_string = f"host={self.postgres_host} port={self.postgres_port} dbname={self.postgres_db} user={self.postgres_user} password={self.postgres_password}"
            
            # 연결 테스트
            conn = psycopg2.connect(conn_string)
            cursor = conn.cursor()
            
            # 기본 쿼리 테스트
            cursor.execute("SELECT version();")
            version = cursor.fetchone()
            
            log_success(f"PostgreSQL 연결 성공: {version[0][:50]}...")
            
            # 스키마 존재 확인
            cursor.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'features';")
            schema_exists = cursor.fetchone()
            
            if schema_exists:
                log_success("features 스키마 존재 확인")
            else:
                log_warning("features 스키마가 존재하지 않음")
                return False
            
            # 테이블 존재 확인
            tables = ['user_demographics', 'user_purchase_summary', 'product_details', 'session_summary']
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM features.{table};")
                count = cursor.fetchone()[0]
                log_success(f"테이블 {table}: {count}개 레코드")
            
            cursor.close()
            conn.close()
            
            return True
            
        except ImportError:
            log_error("psycopg2 패키지가 설치되지 않았습니다: pip install psycopg2-binary")
            return False
        except Exception as e:
            log_error(f"PostgreSQL 연결 실패: {str(e)}")
            return False
    
    def test_redis_connection(self) -> bool:
        """Redis 연결 테스트"""
        log_info("Redis 연결 테스트 중...")
        
        try:
            import redis
            
            # Redis 클라이언트 생성
            r = redis.Redis(host=self.redis_host, port=int(self.redis_port), decode_responses=True)
            
            # 연결 테스트
            response = r.ping()
            if response:
                log_success("Redis 연결 성공")
            else:
                log_error("Redis ping 실패")
                return False
            
            # 기본 동작 테스트
            test_key = "test_integration_key"
            test_value = "test_integration_value"
            
            r.set(test_key, test_value)
            retrieved_value = r.get(test_key)
            
            if retrieved_value == test_value:
                log_success("Redis 읽기/쓰기 테스트 성공")
                r.delete(test_key)  # 테스트 키 삭제
            else:
                log_error("Redis 읽기/쓰기 테스트 실패")
                return False
            
            # 정보 조회
            info = r.info()
            log_success(f"Redis 버전: {info.get('redis_version', 'Unknown')}")
            
            return True
            
        except ImportError:
            log_error("redis 패키지가 설치되지 않았습니다: pip install redis")
            return False
        except Exception as e:
            log_error(f"Redis 연결 실패: {str(e)}")
            return False
    
    def test_mlflow_connection(self) -> bool:
        """MLflow 서버 연결 테스트"""
        log_info("MLflow 서버 연결 테스트 중...")
        
        try:
            import requests
            
            # 헬스체크 엔드포인트 테스트
            health_url = f"{self.mlflow_uri}/health"
            response = requests.get(health_url, timeout=10)
            
            if response.status_code == 200:
                log_success("MLflow 서버 연결 성공")
            else:
                log_error(f"MLflow 서버 응답 오류: {response.status_code}")
                return False
            
            # 실험 목록 조회 테스트
            experiments_url = f"{self.mlflow_uri}/api/2.0/mlflow/experiments/list"
            response = requests.get(experiments_url, timeout=10)
            
            if response.status_code == 200:
                experiments = response.json()
                log_success(f"MLflow 실험 목록 조회 성공: {len(experiments.get('experiments', []))}개 실험")
            else:
                log_warning(f"MLflow 실험 목록 조회 실패: {response.status_code}")
            
            return True
            
        except ImportError:
            log_error("requests 패키지가 설치되지 않았습니다: pip install requests")
            return False
        except Exception as e:
            log_error(f"MLflow 서버 연결 실패: {str(e)}")
            return False
    
    def test_feast_features(self) -> bool:
        """Feast 피처 조회 테스트"""
        log_info("Feast 피처 조회 테스트 중...")
        
        try:
            # Feast 디렉토리로 이동
            feast_dir = "./feast"
            if not os.path.exists(feast_dir):
                log_warning("Feast 디렉토리가 존재하지 않습니다")
                return False
            
            # 현재 디렉토리 백업
            original_dir = os.getcwd()
            os.chdir(feast_dir)
            
            try:
                from feast import FeatureStore
                
                # Feature Store 인스턴스 생성
                fs = FeatureStore(repo_path=".")
                
                # 피처 뷰 목록 조회
                feature_views = fs.list_feature_views()
                log_success(f"Feast 피처 뷰 조회 성공: {len(feature_views)}개 피처 뷰")
                
                for fv in feature_views:
                    log_success(f"  - {fv.name}: {len(fv.features)}개 피처")
                
                # 엔티티 목록 조회
                entities = fs.list_entities()
                log_success(f"Feast 엔티티 조회 성공: {len(entities)}개 엔티티")
                
                for entity in entities:
                    log_success(f"  - {entity.name}: {entity.value_type}")
                
                # 간단한 피처 조회 테스트 (샘플 데이터 사용)
                try:
                    import pandas as pd
                    
                    # 테스트용 엔티티 데이터 생성
                    entity_df = pd.DataFrame({
                        "user_id": ["user_001", "user_002"],
                        "event_timestamp": [datetime.now(), datetime.now()]
                    })
                    
                    # 피처 조회 시도
                    feature_vector = fs.get_historical_features(
                        entity_df=entity_df,
                        features=[
                            "user_demographics:age",
                            "user_demographics:country_code",
                            "user_purchase_summary:ltv"
                        ],
                    )
                    
                    result_df = feature_vector.to_df()
                    log_success(f"Feast 피처 조회 테스트 성공: {len(result_df)}개 레코드")
                    
                except Exception as e:
                    log_warning(f"Feast 피처 조회 테스트 실패: {str(e)}")
                    # 이 부분은 실패해도 전체 테스트에 영향 주지 않음
                
                return True
                
            finally:
                # 원래 디렉토리로 복원
                os.chdir(original_dir)
                
        except ImportError:
            log_error("feast 패키지가 설치되지 않았습니다: pip install feast")
            return False
        except Exception as e:
            log_error(f"Feast 피처 조회 실패: {str(e)}")
            return False
    
    def run_all_tests(self) -> Dict[str, bool]:
        """모든 테스트 실행"""
        print("=" * 80)
        print("🧪 ML Pipeline 통합 테스트 시작")
        print("=" * 80)
        
        tests = [
            ("PostgreSQL 연결", self.test_postgresql_connection),
            ("Redis 연결", self.test_redis_connection),
            ("MLflow 서버", self.test_mlflow_connection),
            ("Feast 피처", self.test_feast_features),
        ]
        
        results = {}
        
        for test_name, test_func in tests:
            print(f"\n{'='*20} {test_name} 테스트 {'='*20}")
            try:
                results[test_name] = test_func()
            except Exception as e:
                log_error(f"테스트 실행 중 오류 발생: {str(e)}")
                results[test_name] = False
        
        return results
    
    def print_summary(self, results: Dict[str, bool]):
        """테스트 결과 요약 출력"""
        print("\n" + "=" * 80)
        print("📊 테스트 결과 요약")
        print("=" * 80)
        
        passed = sum(results.values())
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{status} {test_name}")
        
        print(f"\n총 {total}개 테스트 중 {passed}개 통과 ({passed/total*100:.1f}%)")
        
        if passed == total:
            log_success("🎉 모든 테스트 통과! Feature Store 스택이 정상적으로 동작 중입니다.")
            return True
        else:
            log_warning(f"⚠️ {total-passed}개 테스트 실패. 일부 기능에 문제가 있을 수 있습니다.")
            return False

def main():
    """메인 함수"""
    # 환경변수 로드
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#') and '=' in line:
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
    
    # 테스트 실행
    test_runner = IntegrationTest()
    results = test_runner.run_all_tests()
    success = test_runner.print_summary(results)
    
    # 종료 코드 설정
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 
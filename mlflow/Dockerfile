# MLflow Custom Docker Image
# Blueprint v17.0: mmp-local-dev 환경 개선
# 
# 이 이미지는 MLflow와 PostgreSQL 드라이버를 미리 설치하여,
# 컨테이너 시작 시간을 획기적으로 단축시킵니다.

FROM python:3.11-slim

WORKDIR /app

# requirements.txt 복사 및 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# MLflow 서버 실행
# 필요한 인자(backend-store-uri 등)는 docker-compose.yml에서 command로 추가됩니다.
CMD ["mlflow", "server", "--host", "0.0.0.0"] 
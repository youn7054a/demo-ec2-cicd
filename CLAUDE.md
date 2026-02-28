# EC2 + GitHub Actions CI/CD 프로젝트

## 프로젝트 개요
EC2에 Docker Compose 기반 FastAPI Agent 서비스를 GitHub Actions로 CI/CD 배포하는 프로젝트.

## 아키텍처
- 단일 EC2(Ubuntu 22.04)에서 모든 컨테이너를 `docker compose`로 운영
- 배포: GitHub Actions → SSH로 EC2 접속 → pull → build → up -d

## 서비스 구성
- **FastAPI (web)** - 메인 API 서버 (uvicorn)
- **Celery worker** - 비동기 작업 처리
- **Celery beat** - 주기적 작업 스케줄러 (옵션)
- **Redis** - Celery broker
- **Caddy** - reverse proxy + SSL 자동 발급

## 기술 스택 및 컨벤션
- Python 3.11 slim 기반 Docker 이미지
- FastAPI + Uvicorn
- Celery + Redis (broker URL: `redis://redis:6379/0`)
- Caddy (reverse proxy, SSL 자동)
- GitHub Actions (CI/CD)

## 프로젝트 구조 (산출물)
```
├── Dockerfile                      # Python 3.11 slim, uvicorn CMD
├── docker-compose.yml              # web, worker, beat, redis, caddy
├── Caddyfile                       # 도메인 → reverse_proxy web:8000
├── .env.example                    # 환경변수 템플릿
├── .github/workflows/deploy.yml    # CI/CD 워크플로우
├── DEPLOYMENT.md                   # 운영/배포 가이드
└── scripts/ec2_setup.sh            # EC2 초기 세팅 스크립트 (옵션)
```

## 배포 규칙
- 배포 대상 경로: `/opt/agent-service`
- 모든 서비스는 `restart: always`
- 모든 서비스는 `env_file: .env` 사용
- Caddy만 80/443 포트 expose, web은 내부 네트워크에서만 접근 (`caddy -> web:8000`)
- 도메인 기반 Caddy 설정으로 SSL 자동 발급

## GitHub Actions 배포 워크플로우
- 트리거: `main` 브랜치 push + workflow_dispatch (수동 실행)
- 배포 방식: SSH로 EC2 접속 후 실행
  1. `/opt/agent-service` 없으면 clone, 있으면 pull
  2. `.env` 파일 존재 확인 (없으면 실패)
  3. `docker compose up -d --build`
  4. `docker image prune -f` (디스크 관리)

## 필요한 GitHub Secrets
- `EC2_HOST` - EC2 public IP or domain
- `EC2_USER` - ubuntu
- `EC2_SSH_KEY` - SSH private key (pem 내용)
- `APP_DIR` - /opt/agent-service (옵션)
- `DOMAIN` - yourdomain.com (옵션)

## 필수 구현 사항
- FastAPI는 `/health` 엔드포인트 필수 제공
- Celery는 `REDIS_URL` 환경변수를 broker로 사용
- compose 네트워크에서 `redis` 호스트명으로 접근
- Caddy가 외부 트래픽을 받아 web으로 reverse proxy

## EC2 사전 조건
- Ubuntu 22.04, Docker + Docker Compose 설치
- 보안그룹 인바운드: 22(SSH), 80(HTTP), 443(HTTPS)
- 도메인 A 레코드 → EC2 Public IP

## 완료 조건
- main push 시 GitHub Actions 성공
- EC2에서 `docker compose ps` → web/worker/redis/caddy 모두 Running
- `https://yourdomain.com/health` → 200 OK
- Celery worker가 task 정상 수행

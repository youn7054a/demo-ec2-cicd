# 목표 1: EC2 + GitHub Actions로 FastAPI Agent 서비스 CI/CD 구축

## 개요
이 문서는 **Codex**가 그대로 실행/작성할 수 있도록,  
**EC2에 Docker Compose 기반 FastAPI Agent 서비스를 GitHub Actions로 CI/CD 배포**하는 작업 지시서이다.

배포 대상 서비스 구성:
- **FastAPI (web)**
- **Celery worker**
- **Celery beat (옵션)**
- **Redis (broker)**
- **Caddy (reverse proxy + SSL 자동)**

목표 아키텍처:
- 단일 EC2(= 단일 VPS) 한 대에서 모든 컨테이너를 `docker compose`로 운영
- 배포는 GitHub Actions에서 **SSH로 EC2 접속 → pull → build → up -d** 방식

---

## 사전 조건
- AWS EC2 (Ubuntu 22.04 권장) 1대
- EC2 보안그룹 인바운드:
  - 22 (SSH) : 본인 IP 또는 GitHub Actions runner가 접근 가능한 범위
  - 80 (HTTP) : 0.0.0.0/0
  - 443 (HTTPS) : 0.0.0.0/0
- 도메인 (Caddy SSL 자동발급용) `yourdomain.com` A 레코드가 EC2 Public IP를 가리킴
- GitHub Repo 접근 가능 (private면 deploy key/토큰 필요)

---

## Codex 작업 목록 (To-do)

### 1) EC2 초기 세팅 문서/스크립트 생성
Codex는 아래 작업을 수행하는 **셸 스크립트** 또는 **문서**를 작성한다.

#### 1-1. Docker/Compose 설치
- docker 설치
- docker compose 플러그인 설치(또는 docker-compose 설치)
- 현재 사용자 docker 그룹 추가

#### 1-2. 서버 디렉토리 표준화
- 배포 폴더: `/opt/agent-service`
- 로그/볼륨은 compose volume 사용

#### 1-3. 방화벽(옵션)
- ufw 사용 시 22/80/443 allow

---

### 2) 프로젝트에 Production용 파일 생성/정리
Codex는 저장소에 아래 파일들을 생성/수정한다.

#### 2-1. `Dockerfile`
- Python 3.11 slim 기반
- requirements 설치
- app copy
- 기본 CMD는 web용(uvicorn)

#### 2-2. `docker-compose.yml`
서비스 포함:
- `web`
- `worker`
- `beat`(옵션)
- `redis`
- `caddy`

요구사항:
- 모든 서비스 `restart: always`
- `env_file: .env`
- `caddy`는 80/443 expose
- `web`은 내부 네트워크에서만 접근되도록(직접 port publish 필요 없음) 구성 권장
  - 단, 단순화를 위해 초기에는 publish 없이 `caddy -> web:8000` reverse proxy만 사용

#### 2-3. `Caddyfile`
- `yourdomain.com` → `reverse_proxy web:8000`
- SSL 자동을 위해 도메인 기반 설정 사용

#### 2-4. `.env.example`
- REDIS_URL=redis://redis:6379/0
- 기타 FastAPI 설정값 (ENV=prod, LOG_LEVEL=info 등)

---

### 3) GitHub Actions CI/CD 워크플로우 생성
Codex는 `.github/workflows/deploy.yml` 생성한다.

#### 3-1. 트리거
- `main` 브랜치 push 시 배포
- 수동 실행(workflow_dispatch) 포함

#### 3-2. 방식
- GitHub Actions runner에서 EC2로 SSH 접속하여 아래 실행:
  1) `/opt/agent-service`가 없으면 clone
  2) 있으면 fetch/pull
  3) `.env` 파일 존재 확인(없으면 실패 처리)
  4) `docker compose pull` (옵션)
  5) `docker compose up -d --build`
  6) `docker image prune -f` (옵션, 디스크 관리)

#### 3-3. 필요한 GitHub Secrets
Codex는 README 또는 문서에 아래 Secrets 등록을 안내한다.
- `EC2_HOST` : EC2 public IP or domain
- `EC2_USER` : ubuntu
- `EC2_SSH_KEY` : private key (pem 내용)
- `APP_DIR` : /opt/agent-service (옵션)
- `DOMAIN` : yourdomain.com (옵션)

> SSH key는 GitHub Actions에서 `appleboy/ssh-action` 또는 `ssh-agent` 방식으로 사용 가능

---

### 4) 운영 체크리스트 문서 생성
Codex는 `DEPLOYMENT.md`(또는 `docs/deploy.md`) 생성한다.

포함 내용:
- EC2 세팅 절차
- 도메인/DNS 설정
- `.env` 생성 방법 (서버에서 `/opt/agent-service/.env`)
- 최초 배포 방법
- 배포 확인 방법:
  - `docker compose ps`
  - `docker compose logs -f web`
  - `curl -I https://yourdomain.com/health`
- 롤백 방법(간단):
  - `git checkout <commit>`
  - `docker compose up -d --build`

---

## 필수 구현 세부사항 (중요)
- FastAPI는 최소 `/health` 엔드포인트를 제공해야 함
- Celery는 `REDIS_URL`을 broker로 사용
- compose 네트워크 상에서 `redis` 호스트명으로 접근해야 함
- Caddy가 외부 트래픽을 받아 web로 reverse proxy

---

## 산출물 목록 (Codex가 만들어야 할 파일)
1. `Dockerfile`
2. `docker-compose.yml`
3. `Caddyfile`
4. `.env.example`
5. `.github/workflows/deploy.yml`
6. `DEPLOYMENT.md` (또는 `docs/deploy.md`)
7. (옵션) `scripts/ec2_setup.sh`

---

## 완료 조건 (Acceptance Criteria)
- main 브랜치 push 시 GitHub Actions가 성공
- EC2에서 `docker compose ps` 시 web/worker/redis/caddy 모두 Running
- `https://yourdomain.com/health`가 200 OK 응답
- Celery worker가 task를 정상 수행(간단 테스트 task 포함)

---

## 참고: 서비스 구성 요약
FastAPI Agent 서비스 배포 표준:
**단일 VPS + Compose + Caddy + Redis + Celery**
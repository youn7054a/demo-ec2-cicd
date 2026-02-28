# EC2 + GitHub Actions CI/CD Demo

FastAPI + Celery + Redis + Caddy를 Docker Compose로 EC2에 배포하는 프로젝트.

---

## 내가 해야 할 것

### 1. EC2 인스턴스 준비
- [ ] AWS에서 EC2 생성 (Ubuntu 22.04)
- [ ] 보안그룹 인바운드 규칙 추가:
  - `22` (SSH)
  - `80` (HTTP)
  - `443` (HTTPS)
- [ ] EC2에 SSH 접속 후 초기 세팅 스크립트 실행:
  ```bash
  git clone <이 저장소 URL> /opt/agent-service
  cd /opt/agent-service
  chmod +x scripts/ec2_setup.sh
  ./scripts/ec2_setup.sh
  # 실행 후 재로그인 (docker 그룹 적용)
  ```

### 2. 도메인 연결
- [ ] 도메인 구매 또는 기존 도메인 준비
- [ ] DNS A 레코드 → EC2 Public IP로 설정
- [ ] `Caddyfile`의 `yourdomain.com`을 실제 도메인으로 수정

### 3. 환경변수 설정 (EC2 서버에서)
- [ ] EC2 서버에서 `.env` 파일 생성:
  ```bash
  cd /opt/agent-service
  cp .env.example .env
  # 필요시 vi .env 로 수정
  ```

### 4. GitHub 설정
- [ ] 이 프로젝트를 GitHub에 push
- [ ] GitHub 저장소 → Settings → Secrets and variables → Actions에서 아래 등록:

  | Secret | 값 | 예시 |
  |---|---|---|
  | `EC2_HOST` | EC2 Public IP 또는 도메인 | `3.35.xx.xx` |
  | `EC2_USER` | SSH 사용자명 | `ubuntu` |
  | `EC2_SSH_KEY` | SSH private key 전체 내용 | `.pem` 파일 내용 복붙 |

- [ ] private 저장소인 경우 EC2에서 clone 가능하도록 deploy key 또는 토큰 설정

### 5. 첫 배포
- [ ] `main` 브랜치에 push → GitHub Actions 자동 실행
- [ ] 또는 GitHub Actions 탭에서 수동 실행 (Run workflow)

### 6. 배포 확인
- [ ] EC2에 접속해서 확인:
  ```bash
  cd /opt/agent-service
  docker compose ps          # 모든 서비스 Running 확인
  docker compose logs -f web # 로그 확인
  ```
- [ ] 브라우저에서 확인:
  ```
  https://yourdomain.com/health  → {"status": "ok"} 나오면 성공
  ```

---

## 문제 해결

| 증상 | 확인 방법 |
|---|---|
| Actions 실패 | GitHub Actions 탭에서 로그 확인 → SSH 연결/Secrets 점검 |
| 컨테이너 안 뜸 | `docker compose logs` 로 에러 확인 |
| SSL 안됨 | 도메인 DNS 전파 확인 + `Caddyfile` 도메인 확인 |
| health 응답 없음 | `docker compose ps`로 web 서비스 상태 확인 |

## 롤백
```bash
cd /opt/agent-service
git log --oneline          # 돌아갈 커밋 확인
git checkout <commit-hash>
docker compose up -d --build
```

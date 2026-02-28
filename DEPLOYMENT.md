# 배포 가이드

## 1. EC2 초기 세팅
```bash
# EC2 접속 후
chmod +x scripts/ec2_setup.sh
./scripts/ec2_setup.sh
# 재로그인 (docker 그룹 적용)
```

## 2. 도메인 설정
- 도메인 A 레코드 → EC2 Public IP
- `Caddyfile`의 `yourdomain.com`을 실제 도메인으로 변경

## 3. 환경변수 설정
```bash
cd /opt/agent-service
cp .env.example .env
# 필요시 .env 수정
```

## 4. GitHub Secrets 등록
| Secret | 값 |
|---|---|
| `EC2_HOST` | EC2 Public IP 또는 도메인 |
| `EC2_USER` | ubuntu |
| `EC2_SSH_KEY` | SSH private key 내용 |

## 5. 배포 확인
```bash
docker compose ps
docker compose logs -f web
curl -I https://yourdomain.com/health
```

## 6. 롤백
```bash
cd /opt/agent-service
git checkout <commit-hash>
docker compose up -d --build
```

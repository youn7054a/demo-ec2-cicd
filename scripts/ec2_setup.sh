#!/bin/bash
set -e

# Docker 설치
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 배포 디렉토리 생성
sudo mkdir -p /opt/agent-service
sudo chown $USER:$USER /opt/agent-service

# 방화벽
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "EC2 setup complete. Re-login for docker group to take effect."

#!/bin/bash
set -e

echo "=== Docker & Docker Compose 설치 시작 ==="

# 기존 패키지 업데이트
sudo apt-get update -y
sudo apt-get upgrade -y

# 필요한 패키지 설치
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg-agent

# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker 저장소 등록
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 패키지 업데이트 후 Docker 설치
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 도커 컴포즈 버전 확인 (플러그인 방식)
docker compose version || true

# docker 그룹에 현재 사용자 추가 (재로그인 필요)
sudo usermod -aG docker $USER

echo "=== Docker & Docker Compose 설치 완료 ==="
echo "재로그인 후 'docker run hello-world' 실행해 보세요."


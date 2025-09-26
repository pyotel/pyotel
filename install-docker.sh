#!/bin/bash

echo "==================================="
echo "Docker & Docker Compose 설치 스크립트"
echo "==================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# OS 확인
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}Linux 시스템 감지${NC}"

    # 배포판 확인
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    fi

    # 기존 Docker 제거
    echo -e "${YELLOW}기존 Docker 패키지 제거 중...${NC}"
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null

    # 필수 패키지 설치
    echo -e "${YELLOW}필수 패키지 설치 중...${NC}"
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Docker GPG 키 추가
    echo -e "${YELLOW}Docker GPG 키 추가 중...${NC}"
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Docker 저장소 추가
    echo -e "${YELLOW}Docker 저장소 추가 중...${NC}"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Docker Engine 설치
    echo -e "${YELLOW}Docker Engine 설치 중...${NC}"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Docker Compose 스탠드얼론 설치
    echo -e "${YELLOW}Docker Compose 설치 중...${NC}"
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Docker 서비스 시작
    echo -e "${YELLOW}Docker 서비스 시작 중...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker

    # 현재 사용자를 docker 그룹에 추가
    echo -e "${YELLOW}사용자를 docker 그룹에 추가 중...${NC}"
    sudo usermod -aG docker $USER

    # 설치 확인
    echo -e "${GREEN}설치 확인 중...${NC}"
    docker --version
    docker-compose --version

    echo -e "${GREEN}==================================="
    echo -e "Docker 설치 완료!"
    echo -e "===================================${NC}"
    echo -e "${YELLOW}중요: docker 그룹 권한을 적용하려면 로그아웃 후 다시 로그인하거나"
    echo -e "다음 명령을 실행하세요: newgrp docker${NC}"
    echo ""
    echo -e "${GREEN}Docker 테스트: docker run hello-world${NC}"

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}macOS 시스템 감지${NC}"

    # Homebrew 확인
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Homebrew가 설치되어 있지 않습니다."
        echo -e "먼저 Homebrew를 설치해주세요: https://brew.sh${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Docker Desktop 설치 중...${NC}"
    brew install --cask docker

    echo -e "${GREEN}==================================="
    echo -e "Docker Desktop 설치 완료!"
    echo -e "===================================${NC}"
    echo -e "${YELLOW}Docker Desktop 앱을 실행하여 설정을 완료하세요.${NC}"

else
    echo -e "${RED}지원하지 않는 OS입니다: $OSTYPE${NC}"
    exit 1
fi

# Docker 실행 테스트
echo ""
echo -e "${YELLOW}Docker 설치 테스트를 시작합니다...${NC}"
if sudo docker run hello-world &>/dev/null; then
    echo -e "${GREEN}✓ Docker가 정상적으로 설치되었습니다!${NC}"
else
    echo -e "${RED}✗ Docker 실행 테스트 실패. 수동으로 확인이 필요합니다.${NC}"
fi
#!/bin/bash
set -e

echo ">>> 준비 패키지 설치"
sudo apt-get update -y
sudo apt-get install -y tmux curl build-essential ca-certificates

# (선택) 시스템 전역의 오래된 node/npm 제거
# 이미 다른 곳에서 node를 쓰고 있다면 주석 처리하세요
if command -v node >/dev/null 2>&1 || command -v npm >/dev/null 2>&1; then
  echo ">>> (옵션) 구버전 node/npm 제거 시도"
  sudo apt-get remove -y nodejs npm || true
  sudo apt-get autoremove -y || true
fi

echo ">>> NVM 설치"
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
fi

# 현재 쉘에 nvm 로드
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

echo ">>> Node LTS 설치 및 기본 설정"
# 최신 LTS (현재 Node 20 계열) 설치/사용/기본 지정
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo ">>> 전역 npm 경로를 사용자 홈으로 설정 (sudo 불필요)"
npm config set prefix "$HOME/.npm-global"
# PATH 적용(현재 쉘)
export PATH="$HOME/.npm-global/bin:$PATH"
# 이후 새 세션에도 적용되도록 프로필에 추가
PROFILE_FILE=""
if [ -n "$BASH_VERSION" ]; then PROFILE_FILE="$HOME/.bashrc"; fi
if [ -n "$ZSH_VERSION" ]; then PROFILE_FILE="$HOME/.zshrc"; fi
if [ -z "$PROFILE_FILE" ]; then PROFILE_FILE="$HOME/.profile"; fi
if ! grep -q 'npm-global/bin' "$PROFILE_FILE" 2>/dev/null; then
  {
    echo ''
    echo '# added by claude.sh'
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"'
  } >> "$PROFILE_FILE"
fi

echo ">>> npm 업데이트"
npm install -g npm

echo ">>> 기존 전역 claude 제거(있다면)"
npm rm -g @anthropic-ai/claude-code || true
sudo npm rm -g @anthropic-ai/claude-code || true  # 과거에 sudo로 깔린 흔적 제거

echo ">>> claude-code 전역 설치 (sudo 없이)"
npm install -g @anthropic-ai/claude-code

echo ">>> 설치/경로 확인"
node -v
npm -v
which node
which npm
which claude || true
# 일부 환경에서 즉시 링크가 안 잡힐 수 있어 재해시
hash -r || true

echo ">>> claude 버전 확인"
claude --version

echo "=== 완료 ==="
echo "새 터미널을 열거나 'source $PROFILE_FILE' 실행 후 사용하세요."


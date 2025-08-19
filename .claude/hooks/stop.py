#!/usr/bin/env python3
"""
Claude Code stop hook - sends Telegram notification when Claude Code session ends
"""

import os
import sys
import json
import urllib.request
import urllib.parse
from datetime import datetime

TELEGRAM_BOT_TOKEN = "8219938980:AAEWKrGT21TTaNTvfLvwmT04SwREs6SPt1k"
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

def get_chat_id():
    """Get chat ID from environment variable or config file"""
    chat_id = os.environ.get('TELEGRAM_CHAT_ID')
    
    if not chat_id:
        config_path = os.path.expanduser('~/.claude/telegram_config.json')
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    chat_id = config.get('chat_id')
            except:
                pass
    
    return chat_id

def get_updates():
    """Get recent updates to find chat ID if not configured"""
    try:
        url = f"{TELEGRAM_API_URL}/getUpdates"
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data['ok'] and data['result']:
                latest_update = data['result'][-1]
                if 'message' in latest_update:
                    return latest_update['message']['chat']['id']
    except Exception as e:
        print(f"Error getting updates: {e}", file=sys.stderr)
    return None

def send_telegram_message(message):
    """Send message to Telegram"""
    chat_id = get_chat_id()
    
    if not chat_id:
        print("Attempting to get chat ID from recent messages...", file=sys.stderr)
        chat_id = get_updates()
        
        if chat_id:
            config_path = os.path.expanduser('~/.claude/telegram_config.json')
            os.makedirs(os.path.dirname(config_path), exist_ok=True)
            with open(config_path, 'w') as f:
                json.dump({'chat_id': str(chat_id)}, f)
            print(f"Chat ID {chat_id} saved to config", file=sys.stderr)
    
    if not chat_id:
        print("No Telegram chat ID configured. Send a message to the bot first.", file=sys.stderr)
        print("Bot username: @claude_6483_bot", file=sys.stderr)
        return False
    
    try:
        url = f"{TELEGRAM_API_URL}/sendMessage"
        data = {
            'chat_id': chat_id,
            'text': message,
            'parse_mode': 'Markdown'
        }
        
        data_encoded = urllib.parse.urlencode(data).encode('utf-8')
        req = urllib.request.Request(url, data=data_encoded)
        
        with urllib.request.urlopen(req, timeout=5) as response:
            result = json.loads(response.read().decode())
            return result.get('ok', False)
            
    except Exception as e:
        print(f"Error sending Telegram message: {e}", file=sys.stderr)
        return False

def main():
    """Main function executed when Claude Code stops"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    hostname = os.uname().nodename
    user = os.environ.get('USER', 'unknown')
    working_dir = os.getcwd()
    
    session_id = os.environ.get('CLAUDE_SESSION_ID', 'unknown')
    duration = os.environ.get('CLAUDE_SESSION_DURATION', 'unknown')
    
    message = f"""✅ 작업 완료 알림

🤖 Claude Code 작업이 완료되었습니다!
📅 시간: {timestamp}
📝 처리 내용: Claude Code 세션 종료
🔄 상태: 성공적으로 완료됨

간단한 정보:
- 작업 유형: 코드 작업 세션
- 호스트: {hostname}
- 사용자: {user}
- 작업 디렉토리: {working_dir}
- 응답 완료: ✓"""
    
    if send_telegram_message(message):
        print("Stop notification sent to Telegram", file=sys.stderr)
    else:
        print("Failed to send stop notification", file=sys.stderr)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(1)

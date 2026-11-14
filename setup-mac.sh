#!/bin/bash
# Vibe coding lecture setup for macOS — everything in one run.
# 1) Git (Xcode Command Line Tools)  2) Node.js 22  3) Firebase CLI  4) Claude desktop app
# 5) firebase login  6) Claude setting "allow bypass permissions mode"  7) open the Firebase console
#
# Run in Terminal:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/setup-mac.sh)"
#
# Do NOT pipe this script into bash (curl ... | bash): sudo and `firebase login` need the keyboard.

set -u

TOTAL=7
NODE_MAJOR_WANTED=22
NODE_MAJOR_MIN=20
NPM_GLOBAL="$HOME/.npm-global"
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"

cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
step()   { echo; cyan "[$1/$TOTAL] $2"; }
ok()     { green "  [OK] $*"; }
warn()   { yellow "  [!] $*"; }

fail() {
  echo
  red "  [X] 문제가 생겼어요: $*"
  red '  이 창을 캡처해서 Claude 앱에 "이런 화면이 나왔어. 어떻게 해?" 라고 물어보세요.'
  red '  한 번 더 실행해도 괜찮아요. 이미 끝난 단계는 건너뛰어요.'
  red '  그래도 안 되면 단톡방에 캡처와 함께 남겨 주세요.'
  exit 1
}

# Make tools installed by this script (or earlier) visible in this window.
export PATH="$NPM_GLOBAL/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

node_major() {
  command -v node >/dev/null 2>&1 || { echo 0; return; }
  node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'
}

add_path_line() {
  local line='export PATH="$HOME/.npm-global/bin:$PATH"'
  for rc in "$HOME/.zprofile" "$HOME/.bash_profile"; do
    touch "$rc"
    grep -qF '.npm-global/bin' "$rc" || printf '\n%s\n' "$line" >> "$rc"
  done
}

claude_app() {
  for p in "/Applications/Claude.app" "$HOME/Applications/Claude.app"; do
    [ -d "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

install_claude() {
  # Homebrew's cask API carries the current official download URL (no Homebrew needed).
  local url dest
  url=$(curl -fsSL https://formulae.brew.sh/api/cask/claude.json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).url)}catch(e){}})')
  if [ -n "$url" ]; then
    echo "  내려받는 중: Claude"
    if curl -fL --progress-bar -o /tmp/Claude.zip "$url"; then
      dest="/Applications"
      [ -w "$dest" ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
      rm -rf "$dest/Claude.app"
      ditto -xk /tmp/Claude.zip "$dest" && return 0
    fi
  fi
  warn '자동 설치가 안 됐어요. 브라우저에서 Claude 다운로드 페이지를 열게요.'
  warn '받은 파일을 열어 Claude 를 "응용 프로그램" 폴더로 옮겨 주세요.'
  open 'https://claude.com/download'
  read -r -p '  설치가 끝나면 여기로 돌아와서 엔터 '
  claude_app >/dev/null || fail 'Claude 앱을 찾지 못했어요.'
}

# Sets preferences.bypassPermissionsModeEnabled = true in claude_desktop_config.json.
# Only this one key is touched; a .bak copy is kept. The per-account warning consent is left to the app.
enable_bypass_setting() {
  pkill -x Claude >/dev/null 2>&1 && sleep 2
  mkdir -p "$CLAUDE_CONFIG_DIR" || return 1
  local f="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"
  [ -f "$f" ] && cp "$f" "$f.bak"
  CFG="$f" node -e '
    const fs = require("fs"); const f = process.env.CFG;
    let c = {};
    if (fs.existsSync(f)) c = JSON.parse(fs.readFileSync(f, "utf8"));
    c.preferences = c.preferences || {};
    c.preferences.bypassPermissionsModeEnabled = true;
    fs.writeFileSync(f, JSON.stringify(c, null, 2));
  '
}

echo
cyan '================================================'
cyan '  바이브 코딩 특강 준비를 시작해요 (맥)'
cyan '  15분쯤 걸려요. 창을 닫지 말고 기다려 주세요.'
cyan '================================================'

# 1. Git via Xcode Command Line Tools. /usr/bin/git exists as a stub even without them, so check xcode-select.
step 1 'Git'
if xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
  ok "이미 설치되어 있어요: $(git --version)"
else
  xcode-select --install >/dev/null 2>&1
  yellow '  화면에 "명령어 라인 개발자 도구" 설치 창이 떠요 → [설치] → [동의] 를 눌러 주세요.'
  yellow '  설치가 끝날 때까지 여기서 기다릴게요 (5~15분).'
  waited=0
  until xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; do
    sleep 10
    waited=$((waited + 10))
    if [ $((waited % 60)) -eq 0 ]; then
      echo "  아직 설치 중이에요... ($((waited / 60))분 지남)"
      [ $((waited % 300)) -eq 0 ] && yellow '  설치 창이 안 보이면 이 창을 닫고 처음부터 다시 실행해 주세요.'
    fi
    [ "$waited" -ge 3600 ] && fail 'Git 설치가 1시간 안에 끝나지 않았어요.'
  done
  ok "설치 완료: $(git --version)"
fi

# 2. Node.js from the official .pkg (no Homebrew needed).
step 2 "Node.js $NODE_MAJOR_WANTED"
major=$(node_major)
if [ "${major:-0}" -ge "$NODE_MAJOR_MIN" ]; then
  ok "이미 설치되어 있어요: $(node -v)"
else
  [ "${major:-0}" -gt 0 ] && echo "  지금 Node.js 버전($(node -v))이 너무 낮아서 $NODE_MAJOR_WANTED 버전을 설치할게요."
  base="https://nodejs.org/dist/latest-v$NODE_MAJOR_WANTED.x"
  pkg=$(curl -fsSL "$base/SHASUMS256.txt" | awk '{print $2}' | grep -E '^node-v[0-9.]+\.pkg$' | head -n 1)
  [ -n "$pkg" ] || fail 'Node.js 설치 파일을 찾지 못했어요.'
  echo "  내려받는 중: $pkg"
  curl -fL --progress-bar -o "/tmp/$pkg" "$base/$pkg" || fail 'Node.js 를 내려받지 못했어요.'
  yellow '  "Password:" 가 나오면 맥 로그인 비밀번호를 치고 엔터를 눌러 주세요.'
  yellow '  (비밀번호는 쳐도 화면에 안 보이는 게 정상이에요)'
  sudo installer -pkg "/tmp/$pkg" -target / || fail 'Node.js 설치가 끝나지 않았어요.'
  hash -r
  ok "설치 완료: $(node -v)"
fi

# 3. Firebase CLI. Use a per-user npm prefix when the global folder needs sudo (official .pkg installs).
step 3 'Firebase CLI'
if command -v firebase >/dev/null 2>&1; then
  ok "이미 설치되어 있어요: $(firebase --version)"
else
  if [ ! -w "$(npm prefix -g)/lib" ] && [ ! -w "$(npm prefix -g)" ]; then
    mkdir -p "$NPM_GLOBAL"
    npm config set prefix "$NPM_GLOBAL"
    add_path_line
  fi
  echo '  설치 중이에요. 1~3분 걸려요...'
  npm install -g firebase-tools --no-fund --no-audit --loglevel=error || fail 'Firebase CLI 설치가 끝나지 않았어요.'
  hash -r
  command -v firebase >/dev/null 2>&1 || fail 'Firebase CLI 를 찾지 못했어요.'
  ok "설치 완료: $(firebase --version)"
fi

# 4. Claude desktop app.
step 4 'Claude 데스크톱 앱'
if claude_app >/dev/null; then ok '이미 설치되어 있어요'; else install_claude; ok '설치 완료'; fi

# 5. Interactive Firebase login in this window.
step 5 'Firebase 로그인'
yellow '  1) 영어로 "Allow Firebase to collect ... (Y/n)" 라고 물으면  n  치고 엔터'
yellow '     그 밖에 영어로 (Y/n) 질문이 더 나오면 그냥 엔터'
yellow '  2) 브라우저가 열리면 내 구글 계정 선택 → [허용]'
yellow '  3) 브라우저에 "Login Successful" 이 나오면 이 창으로 돌아오세요'
echo
firebase login || fail 'Firebase 로그인이 끝나지 않았어요.'

# 6. Claude setting.
step 6 'Claude 설정: "권한 우회 모드 허용" 켜기'
echo '  Claude 앱을 잠깐 껐다가 다시 켤게요.'
if enable_bypass_setting; then ok '설정 완료'; else warn '자동 설정이 안 됐어요. 안내문 4번 그림대로 직접 켜 주세요.'; fi
app=$(claude_app) && open "$app"

# 7. Firebase console terms.
step 7 'Firebase 약관 동의'
yellow '  브라우저에서 Firebase 콘솔을 열게요. 약관이 나오면 동의만 해 주세요 (프로젝트는 안 만들어도 돼요).'
open 'https://console.firebase.google.com'

echo
green '================================================'
green '  설치가 모두 끝났어요! 아래 세 줄을 캡처해 두세요'
green "    node -v            → $(node -v)"
green "    git --version      → $(git --version)"
green "    firebase --version → $(firebase --version)"
echo
green '  남은 일은 두 가지예요:'
green '    - 방금 열린 Claude 앱에 로그인하기 (유료 구독 계정)'
green '    - 브라우저의 Firebase 콘솔에서 약관 동의하기'
green '================================================'

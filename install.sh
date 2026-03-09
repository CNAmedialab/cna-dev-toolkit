#!/bin/bash
# CNA Dev Toolkit Installer
# 一鍵安裝所有開發工具

set -euo pipefail

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}" >&2; exit 1; }

# 取得腳本目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"

echo "=================================="
echo "🚀 CNA Dev Toolkit Installer"
echo "=================================="
echo ""

# 1. 檢查依賴
info "檢查依賴..."

# 必要依賴
if ! command -v git &> /dev/null; then
  error "git 未安裝。請先安裝 git: https://git-scm.com/"
fi
success "git 已安裝"

# Shell 檢查
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
  SHELL_NAME="zsh"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
  SHELL_NAME="bash"
else
  SHELL_RC="$HOME/.zshrc"  # 預設建立 .zshrc
  SHELL_NAME="zsh"
  warning "未找到 .zshrc 或 .bashrc，將建立 .zshrc"
fi
success "Shell: $SHELL_NAME ($SHELL_RC)"

# 可選依賴
OPTIONAL_DEPS=()
if ! command -v gh &> /dev/null; then
  OPTIONAL_DEPS+=("gh (GitHub CLI)")
fi
if ! command -v jq &> /dev/null; then
  OPTIONAL_DEPS+=("jq")
fi
if ! command -v curl &> /dev/null; then
  OPTIONAL_DEPS+=("curl")
fi

if [ ${#OPTIONAL_DEPS[@]} -gt 0 ]; then
  warning "可選依賴未安裝: ${OPTIONAL_DEPS[*]}"
  echo "  部分功能可能無法使用："
  echo "  - gh: GitHub Issues 管理"
  echo "  - jq: JSON 處理"
  echo "  - curl: MAV Council"
  echo ""
  echo "  安裝方式："
  echo "  brew install gh jq"
  echo ""
  read -p "  是否繼續安裝？[Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    exit 1
  fi
fi

echo ""

# 2. 建立目標目錄
info "建立目標目錄..."

# 模板目錄：優先使用環境變數，否則使用預設位置
TEMPLATES_DIR="${TEMPLATES_DIR:-$HOME/.cursor/templates}"

mkdir -p "$HOME/.cursor/scripts"
mkdir -p "$TEMPLATES_DIR/context"
mkdir -p "$TEMPLATES_DIR/commands"
mkdir -p "$HOME/.claude/skills"

success "目標目錄已建立"
info "模板目錄: $TEMPLATES_DIR"

# 3. 複製腳本
info "安裝腳本..."

cp "$TOOLKIT_DIR/scripts/newproject.sh" "$HOME/.cursor/scripts/"
cp "$TOOLKIT_DIR/scripts/repo-snapshot.sh" "$HOME/.cursor/scripts/"
chmod +x "$HOME/.cursor/scripts/newproject.sh"
chmod +x "$HOME/.cursor/scripts/repo-snapshot.sh"

success "newproject.sh 已安裝到 ~/.cursor/scripts/"
success "repo-snapshot.sh 已安裝到 ~/.cursor/scripts/"

# issue-helpers.sh 保留在 toolkit 目錄（透過 source 使用）
chmod +x "$TOOLKIT_DIR/scripts/issue-helpers.sh"
success "issue-helpers.sh 已準備就緒"

# council-query.sh 也保留在 toolkit 目錄
chmod +x "$TOOLKIT_DIR/scripts/council-query.sh"
success "council-query.sh 已準備就緒"

# 4. 複製模板
info "安裝模板..."

cp "$TOOLKIT_DIR/templates/CLAUDE.md.tmpl" "$TEMPLATES_DIR/"
cp "$TOOLKIT_DIR/templates/gitignore.tmpl" "$TEMPLATES_DIR/"
cp -r "$TOOLKIT_DIR/templates/context/"* "$TEMPLATES_DIR/context/"
cp "$TOOLKIT_DIR/templates/commands/"* "$TEMPLATES_DIR/commands/"

success "模板已安裝到 $TEMPLATES_DIR"

# 5. 複製 skills
info "安裝 skills..."

cp "$TOOLKIT_DIR/.claude/skills/mav-council.md" "$HOME/.claude/skills/"

success "skills 已安裝到 ~/.claude/skills/"

# 6. 設定 shell aliases
info "設定 shell aliases..."

# 檢查是否已經加入過
if grep -q "# CNA Dev Toolkit aliases" "$SHELL_RC" 2>/dev/null; then
  warning "Aliases 已存在，跳過"
else
  cat >> "$SHELL_RC" <<EOF

# CNA Dev Toolkit aliases
alias newproject='bash ~/.cursor/scripts/newproject.sh'
alias council-query='bash $TOOLKIT_DIR/scripts/council-query.sh'

# Issue helpers (載入函數)
source $TOOLKIT_DIR/scripts/issue-helpers.sh 2>/dev/null || true
EOF
  success "Aliases 已加入到 $SHELL_RC"
fi

# 7. 驗證安裝
echo ""
info "驗證安裝..."

ERRORS=0

if [ -f "$HOME/.cursor/scripts/newproject.sh" ]; then
  success "newproject.sh 安裝成功"
else
  error "newproject.sh 安裝失敗"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$TEMPLATES_DIR/CLAUDE.md.tmpl" ]; then
  success "模板安裝成功"
else
  error "模板安裝失敗"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$HOME/.claude/skills/mav-council.md" ]; then
  success "Skills 安裝成功"
else
  warning "Skills 安裝失敗（不影響基本功能）"
fi

echo ""

# 8. 安裝完成
if [ $ERRORS -eq 0 ]; then
  echo "=================================="
  success "安裝完成！"
  echo "=================================="
  echo ""
  echo "下一步："
  echo ""
  echo "1. 重新載入 shell 配置："
  echo "   ${GREEN}source $SHELL_RC${NC}"
  echo "   或開新終端機視窗"
  echo ""
  echo "2. 建立第一個專案："
  echo "   ${GREEN}newproject${NC}"
  echo ""
  echo "3. 管理 GitHub Issues："
  echo "   ${GREEN}ghib \"bug 標題\" \"描述\" \"專案名稱\"${NC}"
  echo "   ${GREEN}ghif \"feature 標題\" \"描述\" \"專案名稱\"${NC}"
  echo ""
  echo "4. 多模型協作（需先設定 OpenRouter API key）："
  echo "   ${GREEN}council-query \"你的問題\"${NC}"
  echo ""
  echo "完整說明: ${BLUE}cat $TOOLKIT_DIR/README.md${NC}"
  echo ""
else
  error "安裝過程中發生 $ERRORS 個錯誤，請檢查上方訊息"
fi

# 9. 可選：設定 GitHub CLI
echo ""
if command -v gh &> /dev/null; then
  if ! gh auth status &> /dev/null; then
    warning "GitHub CLI 未認證"
    echo ""
    read -p "是否現在進行 GitHub 認證？[Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      gh auth login
    else
      echo "稍後可執行: ${GREEN}gh auth login${NC}"
    fi
  else
    success "GitHub CLI 已認證"
  fi
fi

# 10. 可選：設定 OpenRouter
echo ""
if [ -z "${OPENROUTER_API_KEY:-}" ]; then
  warning "OpenRouter API key 未設定（MAV Council 需要）"
  echo ""
  read -p "是否現在設定 OpenRouter API key？[y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "請前往 https://openrouter.ai/keys 取得 API key"
    read -p "請輸入你的 OpenRouter API key: " OPENROUTER_KEY
    echo "export OPENROUTER_API_KEY=\"$OPENROUTER_KEY\"" >> "$SHELL_RC"
    success "API key 已儲存到 $SHELL_RC"
    echo "請執行: ${GREEN}source $SHELL_RC${NC}"
  else
    echo "稍後可手動設定："
    echo "  1. 前往 https://openrouter.ai/keys 取得 key"
    echo "  2. 執行: ${GREEN}echo 'export OPENROUTER_API_KEY=\"sk-or-v1-...\"' >> $SHELL_RC${NC}"
  fi
fi

echo ""
success "🎉 安裝程序完成！"

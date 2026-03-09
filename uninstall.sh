#!/bin/bash
# CNA Dev Toolkit Uninstaller
# 移除所有已安裝的檔案和配置

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
error() { echo -e "${RED}❌ $1${NC}" >&2; }

echo "=================================="
echo "🗑️  CNA Dev Toolkit Uninstaller"
echo "=================================="
echo ""

warning "這將移除所有 CNA Dev Toolkit 安裝的檔案"
echo ""
echo "將會移除："
echo "  - ~/.cursor/scripts/newproject.sh"
echo "  - ~/.cursor/scripts/repo-snapshot.sh"
echo "  - ~/.cursor/templates/"
echo "  - ~/.claude/skills/mav-council.md"
echo "  - ~/.cna-toolkit.sh"
echo "  - ~/.zshrc 中的 source 行"
echo ""

read -p "確定要繼續嗎？[y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消移除"
    exit 0
fi

echo ""
info "開始移除..."

# 1. 移除腳本
if [ -f "$HOME/.cursor/scripts/newproject.sh" ]; then
    rm "$HOME/.cursor/scripts/newproject.sh"
    success "已移除 newproject.sh"
else
    info "newproject.sh 不存在"
fi

if [ -f "$HOME/.cursor/scripts/repo-snapshot.sh" ]; then
    rm "$HOME/.cursor/scripts/repo-snapshot.sh"
    success "已移除 repo-snapshot.sh"
else
    info "repo-snapshot.sh 不存在"
fi

# 2. 移除模板
if [ -d "$HOME/.cursor/templates" ]; then
    warning "即將移除 ~/.cursor/templates/"
    read -p "確定移除模板目錄？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.cursor/templates"
        success "已移除 templates/"
    else
        info "保留 templates/"
    fi
else
    info "templates/ 不存在"
fi

# 3. 移除 skills
if [ -f "$HOME/.claude/skills/mav-council.md" ]; then
    rm "$HOME/.claude/skills/mav-council.md"
    success "已移除 mav-council skill"
else
    info "mav-council skill 不存在"
fi

# 4. 移除配置檔
if [ -f "$HOME/.cna-toolkit.sh" ]; then
    rm "$HOME/.cna-toolkit.sh"
    success "已移除 ~/.cna-toolkit.sh"
else
    info "~/.cna-toolkit.sh 不存在"
fi

# 5. 從 .zshrc 移除 source 行
SHELL_RC="$HOME/.zshrc"
if [ -f "$SHELL_RC" ]; then
    if grep -q ".cna-toolkit.sh" "$SHELL_RC"; then
        # 建立備份
        cp "$SHELL_RC" "$SHELL_RC.backup-$(date +%Y%m%d-%H%M%S)"
        success "已備份 .zshrc"

        # 移除 source 行
        sed -i.tmp '/# CNA Dev Toolkit/d' "$SHELL_RC"
        sed -i.tmp '/\.cna-toolkit\.sh/d' "$SHELL_RC"
        rm -f "$SHELL_RC.tmp"

        success "已從 .zshrc 移除配置"
    else
        info ".zshrc 中無 CNA Dev Toolkit 配置"
    fi
fi

# 6. 清理空目錄
if [ -d "$HOME/.cursor/scripts" ] && [ -z "$(ls -A $HOME/.cursor/scripts)" ]; then
    rmdir "$HOME/.cursor/scripts"
    info "已移除空目錄 ~/.cursor/scripts"
fi

if [ -d "$HOME/.cursor" ] && [ -z "$(ls -A $HOME/.cursor)" ]; then
    rmdir "$HOME/.cursor"
    info "已移除空目錄 ~/.cursor"
fi

if [ -d "$HOME/.claude/skills" ] && [ -z "$(ls -A $HOME/.claude/skills)" ]; then
    rmdir "$HOME/.claude/skills"
    info "已移除空目錄 ~/.claude/skills"
fi

if [ -d "$HOME/.claude" ] && [ -z "$(ls -A $HOME/.claude)" ]; then
    rmdir "$HOME/.claude"
    info "已移除空目錄 ~/.claude"
fi

echo ""
success "✅ 移除完成！"
echo ""
echo "📝 注意事項："
echo "  - 專案 aliases 仍存在於 .zshrc，需手動移除"
echo "  - .zshrc 備份在: $SHELL_RC.backup-*"
echo "  - 請執行: source ~/.zshrc"
echo ""
echo "如需重新安裝："
echo "  cd $(dirname "$0") && ./install.sh"

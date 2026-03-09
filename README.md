# CNA Dev Toolkit

> 中央社開發工具包 - 一鍵安裝，立即上手

**3 個核心工具 + AI 協作模板**，讓你快速建立專案並使用 AI 協作開發。

---

## 🚀 安裝（1 分鐘）

```bash
# 克隆到任何你喜歡的位置
git clone https://github.com/CNAmedialab/cna-dev-toolkit.git ~/cna-dev-toolkit
cd ~/cna-dev-toolkit
./install.sh
```

完成後：
```bash
source ~/.zshrc  # 或開新終端機視窗
```

**注意**：你可以將 toolkit 克隆到任何位置（如 `~/tools/`, `~/dev/` 等），安裝腳本會自動處理路徑。

---

## 💡 立即使用

### 1. 建立新專案

```bash
newproject
```

回答幾個問題，專案就建好了，包含：
- ✅ Git repository
- ✅ CLAUDE.md（AI 協作指引）
- ✅ context/（世界模型：ARCHITECTURE.md, DECISIONS.md, LEARNINGS.md）
- ✅ OpenSpec（規格驅動開發）
- ✅ .cursor/commands/（OpenSpec slash commands）
- ✅ .gitignore
- ✅ 自動更新的 repo snapshot
- ✅ Shell alias（快速開啟專案）

### 2. 管理 GitHub Issues

```bash
# 載入 helper functions（安裝後會自動載入）
# 如需手動載入：
source ~/cna-dev-toolkit/scripts/issue-helpers.sh

# 建立 bug issue
ghib "按鈕無反應" "詳細描述..." "your-project"

# 建立 feature issue
ghif "新增深色模式" "使用者可切換主題" "your-project"

# 查看專案的所有 issues
ghil_repo "your-project"

# 認領 issue
ghiclaim 123

# 查看所有可用指令
ghi_help
```

**設定永久載入**：
安裝時已自動設定，無需手動操作。

### 3. 多模型協作（可選）

需要多個 AI 模型一起分析問題時使用。

**前置設定**（一次性）：
```bash
# 1. 取得 OpenRouter API key: https://openrouter.ai/keys
echo 'export OPENROUTER_API_KEY="sk-or-v1-你的key"' >> ~/.zshrc
source ~/.zshrc

# 2. 建立配置
cat > ~/.claude/mav-council.json <<'EOF'
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "openai/gpt-4o",
    "google/gemini-2.0-flash-exp:free"
  ],
  "chairmanModel": "anthropic/claude-sonnet-4-5"
}
EOF
```

**使用**：
```bash
council-query "React vs Vue 哪個更適合新專案？"
```

---

## 📦 內容清單

### 核心工具（4 個腳本）

| 工具 | 功能 | 必要性 |
|------|------|--------|
| `newproject.sh` | 建立新專案（含 AI 協作模板） | ⭐⭐⭐ |
| `issue-helpers.sh` | GitHub Issue 管理（ghib, ghif, ghil 等） | ⭐⭐⭐ |
| `council-query.sh` | 多模型協作查詢（MAV Council） | ⭐⭐ |
| `repo-snapshot.sh` | 更新專案 snapshot 到 CLAUDE.md | ⭐⭐ |

### 專案模板

| 模板 | 用途 |
|------|------|
| `CLAUDE.md.tmpl` | AI 協作指引模板 |
| `gitignore.tmpl` | Git 忽略規則 |
| `context/ARCHITECTURE.md.tmpl` | 系統架構文件 |
| `context/DECISIONS.md.tmpl` | 設計決策記錄 (ADR) |
| `context/LEARNINGS.md.tmpl` | 經驗累積（避免重複犯錯） |
| `commands/openspec-*.md` | OpenSpec slash commands |

### Skills

| Skill | 說明 |
|-------|------|
| `mav-council.md` | MAV Council skill 定義（用於 Claude Code） |

---

## 🔧 依賴需求

執行 `./install.sh` 前，請確認已安裝：

- **必要**：
  - `git`
  - `bash` 或 `zsh`

- **可選**（用於 GitHub Issues）：
  - `gh`（GitHub CLI）- [安裝指南](https://cli.github.com/)
  - `jq`（JSON 處理）- `brew install jq`

- **可選**（用於 OpenSpec）：
  - `openspec` CLI - `npm install -g @openclaw/openspec`

- **可選**（用於 MAV Council）：
  - `curl`
  - OpenRouter API key

---

## ❓ 故障排除

### Q1: 指令找不到（command not found）

**原因**：環境變數未載入

**解決**：
```bash
source ~/.zshrc
# 或開新終端機視窗
```

### Q2: newproject 無法執行

**原因**：權限問題

**解決**：
```bash
chmod +x ~/.cursor/scripts/newproject.sh
```

### Q3: GitHub Issues 相關指令無法使用

**原因**：
1. GitHub CLI 未安裝
2. 未認證

**解決**：
```bash
# 安裝 GitHub CLI
brew install gh

# 認證
gh auth login

# 測試
gh issue list --repo CNAmedialab/main-brain
```

### Q4: council-query 失敗

**原因**：API key 未設定或錯誤

**解決**：
```bash
# 檢查 API key
echo $OPENROUTER_API_KEY

# 如果是空的，重新設定
echo 'export OPENROUTER_API_KEY="sk-or-v1-..."' >> ~/.zshrc
source ~/.zshrc
```

### Q5: 想要更新到最新版

```bash
# 進入你的 toolkit 目錄（根據你安裝的位置）
cd ~/cna-dev-toolkit  # 或你安裝的其他位置
git pull
./install.sh
```

---

## 📚 進階文件

本 toolkit 是精簡版，只包含核心工具。

完整文檔、學習資源、進階功能請參考：
👉 **[main-brain repository](https://github.com/u0401006/main-brain)**

包含：
- 團隊協作工作流程指南
- OpenSpec 使用教學
- Agent Framework 文檔
- 自動化工具（daily brief, health check, learning sync）
- 更多 skills 和範例

---

## 🔄 工作流程範例

### 典型的專案開發流程

```bash
# 1. 建立專案
newproject
# 輸入：my-awesome-project

# 2. 開啟專案（使用自動生成的 alias）
myawesomeproject  # 自動開啟 Cursor

# 3. 使用 OpenSpec 定義規格（可選）
# 在 Cursor 中使用 slash command
# /openspec-proposal

# 4. 在 Claude Code 中開發
# @Claude 請幫我實作用戶登入功能

# 5. 遇到問題記錄到 LEARNINGS.md
# @Claude 請把這次錯誤記錄到 LEARNINGS.md

# 6. Commit
git add .
git commit -m "feat: add user login

Co-Authored-By: Claude <noreply@anthropic.com>"

# 7. 在 GitHub 建立 issue 追蹤下一個任務
ghif "新增深色模式" "使用者可切換主題" "my-awesome-project"

# 8. 查看所有待辦 issues
ghil_repo "my-awesome-project"
```

---

## 🤝 分享給團隊

想要分享這套工具給同事？參考 **[SHARE-WITH-TEAM.md](SHARE-WITH-TEAM.md)** 獲取簡短的分享訊息範本。

---

## 🤝 回報問題 / 建議功能

- **Bug 回報**: [開 Issue](https://github.com/CNAmedialab/cna-dev-toolkit/issues)
- **功能建議**: [開 Issue](https://github.com/CNAmedialab/cna-dev-toolkit/issues)
- **問題討論**: [main-brain discussions](https://github.com/u0401006/main-brain/discussions)

---

## 📄 授權

MIT License

---

## 🙏 致謝

本工具包由 CNA Medialab 團隊與 Claude AI 共同開發。

特別感謝：
- Anthropic Claude - AI 開發夥伴
- main-brain 貢獻者
- 所有使用者的回饋

---

**Built with ❤️ by CNA Medialab**

**版本**: v1.0.0
**最後更新**: 2026-03-09

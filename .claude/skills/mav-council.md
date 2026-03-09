---
name: mav-council
description: 多模型協作智囊團：並行查詢多個 AI 模型（Claude, GPT-4o, Gemini）並綜合最終答案。適用於需要多元視角的複雜問題。
---

# MAV Council - 多模型智囊團

當用戶問題需要多元視角、深度分析或重要決策時，使用此 skill 並行查詢多個 AI 模型。

## 觸發條件

當用戶訊息包含以下關鍵字時考慮使用：
- `council` - 明確要求使用 council
- `多模型` - 想要多個模型的意見
- `智囊團` - 需要多元視角
- `比較一下` - 需要不同觀點
- `各方意見` - 想聽多種看法

或用戶明確要求：
```
用 council 回答這個問題：...
請多個 AI 模型一起分析這個問題
```

## 適用場景

✅ **適合使用**：
- 重要決策（技術選型、架構設計）
- 需要多元視角的問題（比較 A vs B）
- 複雜分析（商業策略、產品規劃）
- 開放性問題（沒有標準答案）

❌ **不適合**：
- 簡單事實查詢
- 單一明確答案的問題
- 時間敏感的快速回答

## 執行方式

### 選項 A：使用 OpenClaw mav-council (推薦)

如果系統已安裝 OpenClaw 和 mav-council：

```bash
cd ~/clawd/skills/mav-council && node council-v2.mjs "用戶的問題"
```

**優點**：
- ✅ 功能完整（互評、動態主席）
- ✅ 已驗證可行
- ✅ 支援多種模型組合

**前置條件**：
- OpenClaw 已安裝
- `~/clawd/mav-council.json` 已配置

**配置範例** (`~/clawd/mav-council.json`)：
```json
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4-5",
    "openai/gpt-4o"
  ],
  "chairmanModel": "anthropic/claude-opus-4-5",
  "enableReview": true
}
```

### 選項 B：使用 OpenRouter 腳本 (Claude Code 專用)

如果只使用 Claude Code，使用自訂腳本：

```bash
bash ~/.claude/scripts/council-query.sh "用戶的問題"
```

**前置條件**：
- 設定 OpenRouter API key
- 腳本已安裝（參考下方「安裝說明」）

## 輸出格式

```
🏛️ MAV Council 執行結果

問題：[用戶的問題]

🤖 模型回應

【Claude Sonnet 4.5】
[回應內容...]

【Claude Opus 4.5】
[回應內容...]

【OpenAI GPT-4o】
[回應內容...]

📊 互評排名 (可選)

1. Claude Opus 4.5 (8.5/10)
   評語：分析最全面，同時考慮技術與商業因素

2. Claude Sonnet 4.5 (8.0/10)
   評語：實戰建議具體，但對缺點分析較少

3. GPT-4o (7.5/10)
   評語：中立平衡，但深度略顯不足

✨ 主席綜合

[綜合所有模型意見的最終答案...]
```

## 使用範例

### 範例 1：技術選型

**用戶**：
```
council: 我們的新專案應該選擇 React 還是 Vue？
團隊有 3 個人，之前主要用 jQuery，預算有限。
```

**執行**：
```bash
cd ~/clawd/skills/mav-council && node council-v2.mjs \
  "新專案應該選擇 React 還是 Vue？團隊有 3 個人，之前主要用 jQuery，預算有限。"
```

### 範例 2：架構決策

**用戶**：
```
用多個模型分析：Microservices vs Monolith 哪個更適合我們的情況？
```

**執行**：
```bash
cd ~/clawd/skills/mav-council && node council-v2.mjs \
  "Microservices vs Monolith 哪個更適合？"
```

### 範例 3：商業策略

**用戶**：
```
智囊團幫我分析：應該先做 B2C 還是 B2B？
```

## 安裝說明

### 方法 A：使用現有 OpenClaw mav-council

已安裝，無需額外設定。

### 方法 B：安裝 Claude Code 專用腳本

#### 步驟 1：設定 OpenRouter

```bash
# 取得 API key: https://openrouter.ai/keys
echo 'export OPENROUTER_API_KEY="sk-or-v1-..."' >> ~/.zshrc
source ~/.zshrc
```

#### 步驟 2：建立配置檔

```bash
cat > ~/.claude/mav-council.json <<'EOF'
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4-5",
    "openai/gpt-4o"
  ],
  "chairmanModel": "anthropic/claude-opus-4-5"
}
EOF
```

#### 步驟 3：安裝腳本

```bash
# 建立腳本目錄
mkdir -p ~/.claude/scripts

# 下載或複製腳本
cp ~/clawd/main-brain/scripts/council-query.sh ~/.claude/scripts/

# 設定執行權限
chmod +x ~/.claude/scripts/council-query.sh
```

#### 步驟 4：測試

```bash
bash ~/.claude/scripts/council-query.sh "測試問題：1+1 等於多少？"
```

## 進階配置

### 自訂模型組合

編輯 `~/clawd/mav-council.json` 或 `~/.claude/mav-council.json`：

```json
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "openai/gpt-4o",
    "google/gemini-2.0-flash-exp",
    "meta-llama/llama-3.1-405b-instruct"
  ],
  "chairmanModel": "anthropic/claude-opus-4-5",
  "enableReview": true,
  "reviewMode": "full"
}
```

### 模型選擇建議

| 模型數量 | 適用場景 | 成本 | 時間 |
|---------|---------|------|------|
| 2 個 | 快速對比 | 低 | 快 |
| 3 個 | 標準決策 | 中 | 適中 |
| 4-5 個 | 重要決策 | 高 | 長 |

**推薦組合**：

**經濟版** (2 模型)：
```json
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "openai/gpt-4o-mini"
  ]
}
```

**標準版** (3 模型，推薦)：
```json
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4-5",
    "openai/gpt-4o"
  ]
}
```

**專業版** (4 模型)：
```json
{
  "models": [
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4-5",
    "openai/gpt-4o",
    "google/gemini-2.0-flash-exp"
  ]
}
```

## Claude Code 使用方式

在 Claude Code 對話中：

```
@Claude 請用 mav-council 幫我分析：
我們的產品應該免費增值 (freemium) 還是訂閱制？
```

**Claude Code 會**：
1. 識別 `mav-council` skill
2. 使用 Bash tool 執行對應腳本
3. 收集所有模型回應
4. 將整合報告呈現給你

## 注意事項

⚠️ **成本**：每次查詢會呼叫多個模型，成本為單次查詢的 3-5 倍

⚠️ **時間**：序列執行約需 1-3 分鐘（取決於模型數量）

⚠️ **API Limit**：注意各 provider 的 rate limit

💡 **建議**：日常問題使用單一模型，重要決策才使用 council

## 故障排除

### 錯誤：Command not found

**原因**：腳本未安裝或路徑錯誤

**解決**：
```bash
# 檢查腳本是否存在
ls -la ~/.claude/scripts/council-query.sh
ls -la ~/clawd/skills/mav-council/council-v2.mjs

# 檢查權限
chmod +x ~/.claude/scripts/council-query.sh
```

### 錯誤：API key invalid

**原因**：API key 未設定或過期

**解決**：
```bash
# 檢查環境變數
echo $OPENROUTER_API_KEY

# 或檢查 OpenClaw 配置
cat ~/.openclaw/openclaw.json | grep -A 5 "env"
```

### 錯誤：Model not available

**原因**：模型名稱錯誤或 provider 不支援

**解決**：
```bash
# OpenRouter 模型需要 provider/model 格式
# ✅ 正確
"anthropic/claude-sonnet-4-5"
"openai/gpt-4o"

# ❌ 錯誤
"claude-sonnet-4-5"
"gpt4o"
```

## 參考資料

- [OpenClaw mav-council](file:///Users/capo_mac_mini/clawd/skills/mav-council)
- [Claude Code Multi-Provider 指南](file:///Users/capo_mac_mini/clawd/main-brain/docs/CLAUDE-CODE-MULTI-PROVIDER.md)
- [OpenRouter 文檔](https://openrouter.ai/docs)
- [MAV Council GitHub Issue](https://github.com/u0401006/main-brain/issues/2)

## 相關連結

- OpenRouter: https://openrouter.ai/
- OpenRouter API Keys: https://openrouter.ai/keys
- Supported Models: https://openrouter.ai/models

---

**版本**: v1.0
**最後更新**: 2026-03-09
**維護者**: main-brain team

#!/bin/bash
# MAV Council Query Script for Claude Code
# 使用 OpenRouter 並行查詢多個 AI 模型並綜合答案

set -euo pipefail

# 配置
CONFIG_FILE="${HOME}/.claude/mav-council.json"
FALLBACK_CONFIG="${HOME}/clawd/mav-council.json"
TEMP_DIR="/tmp/mav-council-$$"

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：錯誤處理
error() {
  echo -e "${RED}❌ Error: $1${NC}" >&2
  exit 1
}

info() {
  echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

success() {
  echo -e "${GREEN}✅ $1${NC}" >&2
}

# 檢查參數
if [ $# -eq 0 ]; then
  cat >&2 <<EOF
Usage: $0 "your question"

Example:
  $0 "React vs Vue 哪個更適合新專案?"

Environment:
  OPENROUTER_API_KEY - OpenRouter API key (required)

Config:
  ~/.claude/mav-council.json - Council configuration
  ~/clawd/mav-council.json - Fallback config
EOF
  exit 1
fi

QUERY="$1"

# 檢查 API key
if [ -z "${OPENROUTER_API_KEY:-}" ]; then
  error "OPENROUTER_API_KEY not set. Get one at: https://openrouter.ai/keys"
fi

# 檢查 jq
if ! command -v jq &> /dev/null; then
  error "jq is required. Install with: brew install jq"
fi

# 讀取配置
if [ -f "$CONFIG_FILE" ]; then
  CONFIG="$CONFIG_FILE"
elif [ -f "$FALLBACK_CONFIG" ]; then
  CONFIG="$FALLBACK_CONFIG"
  info "Using fallback config: $FALLBACK_CONFIG"
else
  error "Config file not found. Create one at: $CONFIG_FILE"
fi

# 解析配置
MODELS=$(jq -r '.models[]' "$CONFIG")
CHAIRMAN=$(jq -r '.chairmanModel' "$CONFIG")
ENABLE_REVIEW=$(jq -r '.enableReview // false' "$CONFIG")

if [ -z "$MODELS" ]; then
  error "No models configured in $CONFIG"
fi

# 建立臨時目錄
mkdir -p "$TEMP_DIR"
trap "rm -rf '$TEMP_DIR'" EXIT

info "🏛️  MAV Council starting..."
info "Models: $(echo "$MODELS" | tr '\n' ', ' | sed 's/,$//')"
info "Chairman: $CHAIRMAN"
echo ""

# 函數：查詢單一模型
query_model() {
  local model="$1"
  local output="$2"

  info "Querying $model..."

  local response
  response=$(curl -s --max-time 60 "https://openrouter.ai/api/v1/chat/completions" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -H "HTTP-Referer: https://github.com/u0401006/main-brain" \
    -H "X-Title: MAV Council" \
    -d @- <<EOF
{
  "model": "$model",
  "messages": [
    {
      "role": "user",
      "content": "$QUERY"
    }
  ],
  "temperature": 0.7
}
EOF
)

  # 檢查錯誤
  if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
    local error_msg
    error_msg=$(echo "$response" | jq -r '.error.message // .error')
    echo "❌ Error: $error_msg" > "$output"
    return 1
  fi

  # 提取回應
  local content
  content=$(echo "$response" | jq -r '.choices[0].message.content // "No response"')
  echo "$content" > "$output"

  success "Got response from $model ($(echo "$content" | wc -c) chars)"
}

# 並行查詢所有模型
INDEX=0
PIDS=()
MODEL_NAMES=()

while IFS= read -r model; do
  MODEL_NAMES+=("$model")
  query_model "$model" "$TEMP_DIR/response-$INDEX.txt" &
  PIDS+=($!)
  ((INDEX++)) || true
done <<< "$MODELS"

# 等待所有查詢完成
info "Waiting for all models to respond..."
for pid in "${PIDS[@]}"; do
  wait "$pid" || true
done

echo ""
success "All models responded!"
echo ""

# 收集回應
RESPONSES=""
RESPONSES_FOR_CHAIRMAN=""
INDEX=0

while IFS= read -r model; do
  if [ -f "$TEMP_DIR/response-$INDEX.txt" ]; then
    RESPONSE=$(cat "$TEMP_DIR/response-$INDEX.txt")
    RESPONSES+="【$model】\n$RESPONSE\n\n"

    # 為主席準備的格式
    RESPONSES_FOR_CHAIRMAN+="模型 $(($INDEX + 1)): $model\n$RESPONSE\n\n---\n\n"
  fi
  ((INDEX++)) || true
done <<< "$MODELS"

# 互評（可選）
REVIEW_SECTION=""
if [ "$ENABLE_REVIEW" = "true" ]; then
  info "Running peer review with chairman model..."

  REVIEW_PROMPT="你是 MAV Council 的評審員。以下是多個 AI 模型對同一問題的回答。

問題：$QUERY

$RESPONSES_FOR_CHAIRMAN

請評估每個模型的回答，依以下標準評分（1-10）：
1. 準確性：資訊正確性
2. 完整性：是否全面回答
3. 實用性：建議是否可行
4. 清晰度：表達是否清楚

請以 markdown 格式輸出排名，格式如下：

## 評審結果

1. **模型名稱** (總分/10)
   - 準確性: X/10
   - 完整性: X/10
   - 實用性: X/10
   - 清晰度: X/10
   - 評語：...

2. ...
"

  REVIEW_RESPONSE=$(curl -s --max-time 90 "https://openrouter.ai/api/v1/chat/completions" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -H "HTTP-Referer: https://github.com/u0401006/main-brain" \
    -H "X-Title: MAV Council Review" \
    -d @- <<EOF | jq -r '.choices[0].message.content // "Review failed"'
{
  "model": "$CHAIRMAN",
  "messages": [
    {
      "role": "user",
      "content": $(echo "$REVIEW_PROMPT" | jq -Rs .)
    }
  ],
  "temperature": 0.3
}
EOF
)

  REVIEW_SECTION="## 📊 互評結果\n\n$REVIEW_RESPONSE\n\n"
fi

# 主席綜合
info "Chairman synthesizing final answer..."

CHAIRMAN_PROMPT="你是 MAV Council 的主席。以下是多個 AI 模型對同一問題的回答。

問題：$QUERY

$RESPONSES_FOR_CHAIRMAN

請綜合以上資訊，產出最終答案。要求：
1. 整合各模型的優點
2. 指出共識與分歧
3. 給出平衡的建議
4. 標註關鍵參考來源（引用哪個模型的論點）

請以清晰、結構化的方式呈現綜合答案。"

FINAL_ANSWER=$(curl -s --max-time 90 "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -H "HTTP-Referer: https://github.com/u0401006/main-brain" \
  -H "X-Title: MAV Council Chairman" \
  -d @- <<EOF | jq -r '.choices[0].message.content // "Synthesis failed"'
{
  "model": "$CHAIRMAN",
  "messages": [
    {
      "role": "user",
      "content": $(echo "$CHAIRMAN_PROMPT" | jq -Rs .)
    }
  ],
  "temperature": 0.5
}
EOF
)

# 輸出完整報告
cat <<REPORT

================================================================================
🏛️  MAV Council 執行結果
================================================================================

問題：$QUERY

模型：$(echo "$MODELS" | tr '\n' ', ' | sed 's/,$//')
主席：$CHAIRMAN

================================================================================
## 🤖 各模型回應
================================================================================

$(echo -e "$RESPONSES")

$(echo -e "$REVIEW_SECTION")

================================================================================
## ✨ 主席綜合答案
================================================================================

$FINAL_ANSWER

================================================================================
執行時間：$(date '+%Y-%m-%d %H:%M:%S')
配置檔案：$CONFIG
================================================================================

REPORT

success "MAV Council completed!"

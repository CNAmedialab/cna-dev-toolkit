# 安全最佳實踐

> 如何安全管理 API keys 和機密資訊

---

## 🚨 問題：直接存放 API Keys 的風險

### 目前的做法（不安全）

```bash
# ❌ 不推薦：直接存在 .zshrc
echo 'export OPENROUTER_API_KEY="sk-or-v1-..."' >> ~/.zshrc

# ❌ 不推薦：直接存在 .env
echo 'OPENROUTER_API_KEY=sk-or-v1-...' > .env
```

### 風險

1. **長期暴露**：密鑰永久存在檔案中，無法輪替
2. **AI 代理洩漏**：Claude Code 可能無意讀取或記錄密鑰
3. **提示注入攻擊**：惡意程式碼可能誘導 AI 讀取 `.env`
4. **無稽核記錄**：無法追蹤密鑰使用情況
5. **版本控制風險**：容易誤 commit 到 git

**參考文章**：[AI エージェント開発における認証情報の安全な管理方法](https://qiita.com/AllegroMoltoV/items/74fce57d602991857107)

---

## ✅ 解決方案：使用 Secret Manager

### 選項 1：Google Cloud Secret Manager（推薦）

#### 為什麼選擇 GCP Secret Manager？

- ✅ **集中管理**：所有密鑰統一管理
- ✅ **IAM 整合**：細緻的權限控制
- ✅ **完整稽核**：Cloud Audit Logs 記錄所有存取
- ✅ **版本控制**：支援密鑰輪替
- ✅ **自動失效**：可設定 TTL
- ✅ **與 GCP 服務整合**：如果已使用 GCP，整合順暢

#### 快速開始

##### 1. 建立 Secret

```bash
# 互動式建立
echo -n "sk-or-v1-your-actual-key" | gcloud secrets create openrouter-api-key \
  --replication-policy="automatic" \
  --data-file=-

# 確認建立成功
gcloud secrets describe openrouter-api-key
```

##### 2. 設定權限

```bash
# 方式 A：給自己的帳號
gcloud secrets add-iam-policy-binding openrouter-api-key \
  --member="user:your-email@example.com" \
  --role="roles/secretmanager.secretAccessor"

# 方式 B：給 service account（推薦）
gcloud secrets add-iam-policy-binding openrouter-api-key \
  --member="serviceAccount:claude-code@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

##### 3. 測試存取

```bash
# 取得最新版本
gcloud secrets versions access latest --secret="openrouter-api-key"

# 應該輸出：sk-or-v1-your-actual-key
```

##### 4. 整合到 council-query

目前 toolkit 的 `council-query.sh` 會自動偵測並使用 Secret Manager：

```bash
# 方法 1：自動從 Secret Manager 取得（最安全）
council-query "React vs Vue 哪個好？"
# → 自動執行：gcloud secrets versions access latest --secret="openrouter-api-key"

# 方法 2：臨時傳入（不留痕跡）
council-query "sk-or-v1-temp-key" "React vs Vue 哪個好？"

# 方法 3：使用環境變數（不推薦）
export OPENROUTER_API_KEY="sk-or-v1-..."
council-query "React vs Vue 哪個好？"
```

#### 進階功能

##### 密鑰輪替

```bash
# 1. 取得新的 API key（從 OpenRouter）
NEW_KEY="sk-or-v1-new-key-here"

# 2. 建立新版本
echo -n "$NEW_KEY" | gcloud secrets versions add openrouter-api-key --data-file=-

# 3. 測試新版本
gcloud secrets versions access latest --secret="openrouter-api-key"

# 4. 停用舊版本（可選）
gcloud secrets versions disable 1 --secret="openrouter-api-key"

# 5. 刪除舊版本（謹慎，不可逆）
gcloud secrets versions destroy 1 --secret="openrouter-api-key"
```

##### 設定 TTL（自動失效）

```bash
# 建立會在 7 天後失效的 secret
gcloud secrets create temp-api-key \
  --replication-policy="automatic" \
  --expire-time="$(date -u -d '+7 days' '+%Y-%m-%dT%H:%M:%SZ')" \
  --data-file=-

# 或使用 TTL（從建立開始計算）
gcloud secrets create temp-api-key \
  --replication-policy="automatic" \
  --ttl="604800s"  # 7 days in seconds
```

##### 使用專用 Service Account

```bash
# 1. 建立 service account
gcloud iam service-accounts create claude-code-sa \
  --display-name="Claude Code Service Account" \
  --description="用於 Claude Code 存取 API keys"

# 2. 授予最小權限
gcloud secrets add-iam-policy-binding openrouter-api-key \
  --member="serviceAccount:claude-code-sa@YOUR_PROJECT.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 3. 建立並下載 key
gcloud iam service-accounts keys create ~/claude-code-sa-key.json \
  --iam-account=claude-code-sa@YOUR_PROJECT.iam.gserviceaccount.com

# 4. 使用 service account
export GOOGLE_APPLICATION_CREDENTIALS=~/claude-code-sa-key.json
council-query "your question"
```

##### 稽核記錄

```bash
# 查看誰存取了 secret
gcloud logging read "resource.type=secretmanager.googleapis.com/Secret \
  AND protoPayload.resourceName:openrouter-api-key" \
  --limit=50 \
  --format=json

# 查看特定時間範圍
gcloud logging read "resource.type=secretmanager.googleapis.com/Secret \
  AND timestamp>=\"2026-03-09T00:00:00Z\"" \
  --limit=50
```

#### 成本

- **免費額度**：
  - 前 6 個活躍 secret 版本：免費
  - 前 10,000 次存取操作：免費
- **付費**：
  - $0.06 per secret per month（超過免費額度）
  - $0.03 per 10,000 access operations

對於個人或小團隊，基本上是免費的。

---

### 選項 2：AWS Secrets Manager

如果使用 AWS：

```bash
# 建立 secret
aws secretsmanager create-secret \
  --name openrouter-api-key \
  --secret-string "sk-or-v1-your-key"

# 取得 secret
aws secretsmanager get-secret-value \
  --secret-id openrouter-api-key \
  --query SecretString \
  --output text
```

修改 `council-query.sh`：
```bash
if command -v aws &> /dev/null; then
  OPENROUTER_API_KEY=$(aws secretsmanager get-secret-value \
    --secret-id openrouter-api-key \
    --query SecretString \
    --output text 2>/dev/null)
fi
```

---

### 選項 3：Azure Key Vault

如果使用 Azure：

```bash
# 建立 key vault
az keyvault create --name my-keyvault --resource-group my-rg --location eastus

# 建立 secret
az keyvault secret set --vault-name my-keyvault \
  --name openrouter-api-key \
  --value "sk-or-v1-your-key"

# 取得 secret
az keyvault secret show --vault-name my-keyvault \
  --name openrouter-api-key \
  --query value \
  --output tsv
```

---

### 選項 4：Bitwarden Secrets Manager

適合個人或小團隊：

```bash
# 安裝 bws CLI
npm install -g @bitwarden/sdk

# 登入
bws login

# 建立 secret
bws secret create openrouter-api-key "sk-or-v1-your-key" --project-id PROJECT_ID

# 使用（只在需要時注入）
bws run --project-id PROJECT_ID -- council-query "your question"
```

**優點**：
- 開源
- 免費方案（3 個 projects, 25 個 secrets）
- 跨平台

---

## 🎯 推薦方案比較

| 方案 | 適用場景 | 成本 | 複雜度 | 推薦度 |
|------|---------|------|--------|--------|
| **GCP Secret Manager** | 已使用 GCP | 基本免費 | 中 | ⭐⭐⭐⭐⭐ |
| **AWS Secrets Manager** | 已使用 AWS | $0.40/secret/month | 中 | ⭐⭐⭐⭐ |
| **Azure Key Vault** | 已使用 Azure | 基本免費 | 中 | ⭐⭐⭐⭐ |
| **Bitwarden SM** | 個人/小團隊 | 免費-$10/月 | 低 | ⭐⭐⭐⭐ |
| **HashiCorp Vault** | 企業級需求 | 自架或付費 | 高 | ⭐⭐⭐ |

---

## 📋 實作檢查清單

### 立即行動（高優先級）

- [ ] 停止將 API keys 存在 `.zshrc` 或 `.env`
- [ ] 選擇適合的 Secret Manager
- [ ] 建立第一個 secret
- [ ] 測試從 Secret Manager 取得密鑰
- [ ] 更新 `council-query.sh` 使用 Secret Manager

### 進階設定（建議）

- [ ] 建立專用 service account
- [ ] 設定 IAM 權限（最小權限原則）
- [ ] 啟用稽核日誌
- [ ] 設定密鑰自動輪替
- [ ] 設定 TTL（臨時密鑰）
- [ ] 文檔化密鑰管理流程

### 團隊協作

- [ ] 為每個團隊成員建立獨立權限
- [ ] 設定密鑰使用政策
- [ ] 定期檢視存取日誌
- [ ] 建立密鑰洩漏應對流程

---

## 🔐 其他安全建議

### 1. 最小權限原則

只給需要的權限：
```bash
# ✅ 只能讀取特定 secret
roles/secretmanager.secretAccessor

# ❌ 不要給過大權限
roles/secretmanager.admin
```

### 2. 使用專案分離

```bash
# 開發環境
gcloud secrets create openrouter-api-key-dev --project=dev-project

# 生產環境
gcloud secrets create openrouter-api-key-prod --project=prod-project
```

### 3. 定期輪替

```bash
# 建議：每 90 天輪替一次
# 可以寫成 cron job
0 0 1 */3 * /path/to/rotate-keys.sh
```

### 4. 監控異常存取

```bash
# 設定 alert
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Secret Access Alert" \
  --condition-display-name="Unusual access pattern"
```

---

## 📚 相關資源

- **GCP Secret Manager 文檔**：https://cloud.google.com/secret-manager/docs
- **AWS Secrets Manager 文檔**：https://docs.aws.amazon.com/secretsmanager/
- **Azure Key Vault 文檔**：https://docs.microsoft.com/azure/key-vault/
- **Bitwarden Secrets Manager**：https://bitwarden.com/products/secrets-manager/
- **參考文章**：https://qiita.com/AllegroMoltoV/items/74fce57d602991857107

---

## 🆘 常見問題

### Q1: 我需要為每個專案建立不同的 secret 嗎？

建議：
- **開發/測試**：可以共用
- **生產環境**：每個專案獨立 secret

### Q2: gcloud 命令執行很慢？

```bash
# 設定 cache
gcloud config set core/enable_cache true

# 或使用環境變數 cache
export SECRET_CACHE_TTL=300  # 5 minutes
```

### Q3: 如何在 CI/CD 中使用？

```bash
# GitHub Actions 範例
- name: Get secret
  run: |
    echo "API_KEY=$(gcloud secrets versions access latest --secret=openrouter-api-key)" >> $GITHUB_ENV

# 之後使用 ${{ env.API_KEY }}
```

### Q4: 成本會很高嗎？

對於個人/小團隊：
- GCP: 基本免費（< 6 secrets, < 10k access/month）
- Bitwarden: 免費方案（< 25 secrets）

---

**最後更新**: 2026-03-09
**維護者**: CNA Dev Toolkit team

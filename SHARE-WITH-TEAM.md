# 分享給團隊 - 一句話指南

> 給同事的工具包，不是教學文件

---

## 🎯 給同事的訊息

```
嘿！我整理了一套開發工具包，幫你快速建立專案和管理 Issues。

安裝（1 分鐘）：
git clone https://github.com/CNAmedialab/cna-dev-toolkit.git ~/clawd/cna-dev-toolkit
cd ~/clawd/cna-dev-toolkit
./install.sh

然後執行：
newproject

就完成了！README 有完整說明。
```

---

## 📦 Toolkit 內容

**4 個工具**：
1. `newproject` - 建立新專案
2. `ghib` / `ghif` - 管理 GitHub Issues
3. `council-query` - 多模型協作（可選）
4. `repo-snapshot` - 更新 snapshot

**模板**：
- CLAUDE.md（AI 協作指引）
- context/（ARCHITECTURE, DECISIONS, LEARNINGS）
- .gitignore

---

## 🔗 連結

- **Toolkit repo**: https://github.com/CNAmedialab/cna-dev-toolkit
- **Release notes**: https://github.com/CNAmedialab/cna-dev-toolkit/releases/tag/v1.0.0
- **完整文檔**（如需要）: https://github.com/u0401006/main-brain

---

## ❓ 常見問題

**Q: 需要看完整文檔嗎？**
A: 不需要。README 有所有必要資訊（~100 行）。

**Q: 跟 main-brain 的關係？**
A: cna-dev-toolkit 是精簡版，只包含核心工具。main-brain 是完整版，包含文檔和進階功能。

**Q: 如何更新？**
A: `cd ~/clawd/cna-dev-toolkit && git pull && ./install.sh`

---

**就這樣！** 🚀

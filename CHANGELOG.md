# Changelog

All notable changes to CNA Dev Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-09

### Added
- ⭐ `newproject.sh` - 建立新專案（含 AI 協作模板）
- ⭐ `issue-helpers.sh` - GitHub Issue 管理（ghib, ghif, ghil 等函數）
- ⭐ `council-query.sh` - MAV Council 多模型協作查詢
- ⭐ `repo-snapshot.sh` - 自動更新專案 snapshot
- ⭐ `install.sh` - 一鍵安裝腳本
- 專案模板：CLAUDE.md, gitignore, context/
- MAV Council skill 定義
- 精簡版 README（立即可用）

### Features
- 零配置安裝
- 自動設定 shell aliases
- 互動式專案建立
- GitHub Issues 快速管理
- 多 LLM provider 支援（透過 OpenRouter）

### Documentation
- README.md - 快速開始指南
- 完整故障排除說明
- 工作流程範例

---

## 版本說明

### v1.0.0 - Initial Release

**目標**：提供立即可用的核心開發工具

**內容**：
- 4 個核心腳本
- 5 個專案模板
- 1 個 skill
- 1 個安裝器

**特色**：
- 🚀 一鍵安裝
- 📦 開箱即用
- 🎯 專注核心功能
- 📖 精簡文檔

**下一版計畫** (v1.1.0)：
- 新增自動化腳本（daily-brief, health-check）
- 支援更多專案模板
- 改進 council-query 輸出格式

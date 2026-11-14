# 參與 Strix 貢獻

感謝你有意願為 Strix 貢獻！本指南會帶你完成開發環境與貢獻流程。

## 🚀 開發環境設置

### 先決條件

- Python 3.12+
- 最新的 Go 1.24.x 修補版本（僅用於 Bubble Tea TUI 開發與發行產物）
- Docker（需正在執行）
- [uv](https://docs.astral.sh/uv/)（用於相依套件管理）
- Git

### 本機開發

1. **複製儲存庫**
   ```bash
   git clone https://github.com/usestrix/strix.git
   cd strix
   ```

2. **安裝開發相依套件**
   ```bash
   make setup-dev

   # 或手動執行：
   uv sync
   uv run pre-commit install
   ```

3. **設定你的 LLM 供應商**
   ```bash
   export STRIX_LLM="openrouter/z-ai/glm-5.3"   # 或 vercel_ai_gateway/zai/glm-5.3
   export LLM_API_KEY="your-api-key"
   ```

4. **以開發模式執行 Strix**
   ```bash
   uv run strix --target https://example.com
   ```

## 📚 貢獻技能

技能是能強化代理能力的專業知識包。詳細規範請見 [strix/skills/README.md](strix/skills/README.md)。

### 快速指南

1. **選擇合適的分類**（`/vulnerabilities`、`/frameworks`、`/technologies` 等）
2. **建立** `.md` 檔案並放入你的技能內容
3. **附上實用範例** —— 可用的 payload、指令或測試案例
4. **提供驗證方法** —— 如何確認發現並避免誤報
5. **透過 PR 提交**，並附上清楚的說明

## 🔧 貢獻程式碼

### Pull Request 流程

1. **先建立 issue** —— 描述問題或功能
2. **Fork 並開分支** —— 從 `main` 分支開始
3. **進行修改** —— 遵循既有程式碼風格
4. **撰寫／更新測試** —— 確保新功能有涵蓋
5. **執行品質檢查** —— `make check-all` 應通過
6. **提交 PR** —— 連結 issue 並提供背景說明

### PR 規範

- **清楚的說明** —— 解釋改了什麼與為什麼
- **小而聚焦的變更** —— 每個 PR 只做一個功能／修正
- **附上範例** —— 展示修改前後的行為
- **更新文件** —— 若新增功能
- **通過所有檢查** —— 測試、lint、型別檢查

### 程式碼風格

- 採 PEP 8，每行上限 100 字元
- 所有函式都要有型別提示
- 公開方法要寫 docstring
- 函式保持聚焦且精簡
- 使用有意義的變數名稱

## 🐛 回報問題

回報 bug 時請附上：

- Python 版本與作業系統
- Strix 版本
- 使用的 LLM
- 完整錯誤追蹤（traceback）
- 重現步驟
- 預期行為與實際行為

## 💡 功能需求

我們歡迎功能的想法！請：

- 先確認是否已有相關 issue
- 清楚描述使用情境
- 說明為何對使用者有幫助
- 思考實作方式
- 保持開放討論

## 🖥️ 本機檢視器 SPA

`strix view` 提供預先建置好的 Web 介面，其原始碼位於
`strix/interface/viewer/frontend/`（Vite + React 專案），建置產物則提交到
`strix/interface/viewer/static/` 並隨套件發佈。終端使用者從不需要執行 JS 建置。
若你修改了 `strix/interface/viewer/frontend/` 下的任何內容，請重新建置並提交產物：

```bash
make viewer   # 或：cd strix/interface/viewer/frontend && npm ci && npm run build
```

請同時提交原始碼變更與重新產生的 `strix/interface/viewer/static/`。

## 套件建置

可編輯安裝不需要 Go；它會直接從原始碼執行 TUI（`go run`）。

Wheel 一律捆綁對應的 Go sidecar，且為平台專屬：

```bash
make wheel
```

建置掛鉤（`scripts/tui_sidecar_hook.py`）會編譯 sidecar、內嵌為
`strix/bin/strix-tui`，並標上目前平台標籤。它需要 Go 1.24.x 或更新版本，
缺少 sidecar 時會直接失敗而不產出 wheel。`scripts/build.sh` 與 `strix.spec`
對凍結的 PyInstaller 發行版同樣嚴格。

## 🤝 社群

- **Discord**：[加入我們的社群](https://discord.gg/strix-ai)
- **Issues**：[GitHub Issues](https://github.com/usestrix/strix/issues)

## ✨ 致謝

我們重視所有貢獻！貢獻者將會：
- 列入發行說明
- 在我們的 Discord 中被感謝
- 加入貢獻者名單（即將推出）

---

**有問題嗎？** 歡迎在 [Discord](https://discord.gg/strix-ai) 發問，或建立 issue。我們很樂意協助！

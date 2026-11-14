# 專案狀態（交接用）

> 給「未來的自己」或「新的 AI 對話」快速掌握現況。
> 最後更新：漢化 + 中文上手包完成時。

---

## 一句話現況

`ssd12588/strix-zh-tw` 是 [usestrix/strix](https://github.com/usestrix/strix) 的**繁體中文漢化版**，
介面、文件、中文上手包都已完成，**尚未做真實掃描驗證**。

- 預設分支：`main`（另有同步分支 `zh-TW`）
- 版本基準：上游 `v1.7.1`
- 授權：Apache-2.0（保留原始 LICENSE）

---

## 已完成

| 範圍 | 位置 | 狀態 |
|---|---|---|
| CLI 介面（`--help`、錯誤訊息、面板） | `strix/interface/*.py` | ✅ |
| TUI 互動介面 | `strix/interface/tui/**` | ✅ |
| Web 檢視器（React） | `strix/interface/viewer/frontend/src/**` + `static/`（已重新建置） | ✅ |
| 官方文件 31 篇 | `docs/**.mdx` | ✅ |
| README / About / AGENTS / CONTRIBUTING | 根目錄 | ✅ |
| 中文上手包 | `docs-zh/` | ✅ |
| Windows 一鍵啟動 | `start-strix.ps1` | ✅ |

**刻意保持英文**（漢化會降低 AI 判斷品質）：
`strix/agents/prompts/*.jinja`、`strix/skills/**`（77 個知識包）、`skills/*/SKILL.md`（9 個，說明段落可考慮漢化）

---

## 驗證狀態

| 檢查 | 指令 | 結果 |
|---|---|---|
| Python 語法 | `python -m py_compile ...` | ✅ |
| Python 測試（CLI 相關 59 項） | `uv run pytest tests/test_cli_* tests/test_main_launch.py -q` | ✅ 59 passed |
| Go 建置 | `cd strix/interface/tui && go build ./...` | ✅ |
| Go 測試 | `cd strix/interface/tui && go test ./...` | ✅ 全綠 |
| 前端建置 | `npm run build`（frontend 目錄） | ✅ |
| 前端型別 | `npx tsc --noEmit` | ✅ 無錯誤 |
| 一鍵腳本 | `.\start-strix.ps1 -Check` | ✅ 顯示中文 |
| **真實掃描** | `strix --target ...` | ⬜ **未驗證（缺 LLM 金鑰）** |

---

## 尚未完成（可選事項）

| 優先 | 項目 | 說明 |
|---|---|---|
| ★★★ | 真實掃描驗證 | 需要 LLM 金鑰；跑一次 `quick` 模式確認漢化不影響功能 |
| ★★★ | `scripts/sync-upstream.ps1` | 一鍵同步上游 + 列出衝突 |
| ★★★ | CI 中文覆蓋率檢查 | GitHub Actions 掃出未翻譯字串 |
| ★★ | GitHub Release | 打 `v1.7.1-zh.1` 標籤與中文發行說明 |
| ★★ | 中文模型指南 | GLM／DeepSeek／Kimi 申請與限額比較 |
| ★ | `skills/*/SKILL.md` 說明段落 | 只翻說明，指令保留英文 |
| ★ | `.github/ISSUE_TEMPLATE` | 2 個檔案，零風險 |
| — | i18n 骨架（字串抽成 `zh-TW.json`） | 工時 3–4 小時，長期最值 |

❌ **不要做**：`strix/skills/**`、`strix/agents/prompts/*.jinja` 的漢化。

---

## 常用指令

```powershell
# 從原始碼執行
uv run strix --target https://example.com
uv run strix --help
uv run strix view

# 一鍵啟動（Windows）
.\start-strix.ps1 -Check
.\start-strix.ps1 -Target https://example.com
.\start-strix.ps1 -ResetConfig

# 前端改動後必須重新建置並提交
cd strix/interface/viewer/frontend
npm run build          # 產物寫入 ../../static/

# 同步上游
git fetch upstream
git merge upstream/main
```

---

## 分支策略

- `main`：對外顯示（GitHub 首頁讀這個）
- `zh-TW`：與 `main` 保持同步（`git merge --ff-only main` 後推送）

---

## 給新對話的開場提示

> 這個倉庫是 `ssd12588/strix-zh-tw`，上游 `usestrix/strix` 的繁體中文漢化版。
> 請先讀 `docs-zh/PROJECT-STATUS.md` 與 `docs-zh/glossary.md` 了解現況與術語，
> 再依 `docs-zh/PROJECT-STATUS.md` 的「尚未完成」清單繼續。
> 漢化時遵守 `docs-zh/glossary.md` 的譯法；不要漢化 `strix/skills/` 與 `prompts/`。

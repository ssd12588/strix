# Strix 漢化版 · 常用指令速查

> 專案路徑：`C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh`
> 兩種呼叫方式都可以：`uv run strix ...`（原始碼）或 `.\start-strix.ps1 ...`（一鍵腳本）

---

## 0. 進入專案（每次開終端機先做）

```powershell
cd C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh
```

---

## 1. 環境檢查

| 目的 | 指令 |
|---|---|
| 看漢化是否生效 | `uv run strix --help` |
| 看版本 | `uv run strix --version` |
| 檢查 Docker | `docker version` |
| 檢查沙箱鏡像 | `docker images \| Select-String strix` |
| 一鍵環境檢查（不耗點數） | `.\start-strix.ps1 -Check` |
| 依賴同步 | `uv sync` |

---

## 2. 設定模型與金鑰

| 目的 | 指令 |
|---|---|
| 互動式設定（推薦） | `.\start-strix.ps1` |
| 重新設定（清除記住的設定） | `.\start-strix.ps1 -ResetConfig` |
| 手動設定（本次視窗有效） | `$env:STRIX_LLM="deepseek/deepseek-v4-pro"; $env:LLM_API_KEY="sk-..."` |
| 用 ChatGPT 訂閱 | `uv run strix auth login chatgpt` |
| 看訂閱登入狀態 | `uv run strix auth status` |
| 登出訂閱 | `uv run strix auth logout` |

> 記住的設定位置：`C:\Users\阿樂\.strix\zh-launcher.json`（含明文金鑰，勿分享）

---

## 3. 跑掃描

| 目的 | 指令 |
|---|---|
| 掃網站 | `uv run strix --target https://你的網站.com` |
| 掃網域 | `uv run strix --target example.org` |
| 掃 IP | `uv run strix --target 192.168.1.10` |
| 掃本機專案（白箱） | `uv run strix --target ./你的專案` |
| 掃 GitHub 專案 | `uv run strix --target https://github.com/帳號/專案` |
| 多個目標 | `uv run strix -t https://a.com -t https://b.com` |
| 從檔案讀目標 | `uv run strix --target-list ./targets.txt` |
| 用一鍵腳本 | `.\start-strix.ps1 -Target https://你的網站.com` |
| 練習用靶場（合法） | `uv run strix --target https://public-firing-range.appspot.com` |

### 掃描模式與成本控制

| 目的 | 加上參數 |
|---|---|
| 快速（幾分鐘，適合 CI） | `--scan-mode quick` |
| 標準（約 30 分鐘） | `--scan-mode standard` |
| 深度（1–4 小時，預設） | `--scan-mode deep` |
| 限制花費（美元） | `--max-budget 2` |
| 限制每個代理回合數 | `--max-turns 300` |
| 無介面（CI／背景執行） | `-n` 或 `--non-interactive` |
| 只在嚴重漏洞時失敗 | `-n --fail-on high` |

**範例（省錢又快速）**

```powershell
uv run strix --target https://你的網站.com --scan-mode quick --max-budget 2
```

### 帶自訂指令（帳密、範圍）

```powershell
uv run strix --target https://你的網站.com --instruction "登入用 test@example.com / Pass123"
uv run strix --target https://你的網站.com --instruction "只測 /api/users，不要測 /admin"
uv run strix --target https://你的網站.com --instruction-file ./指示.md
```

### 給代理額外檔案（字典、API 規格）

```powershell
uv run strix --target https://你的網站.com --workspace-file ./wordlist.txt
uv run strix --target https://你的網站.com --workspace-file ./openapi.yaml:specs/openapi.yaml
```

---

## 4. 看結果

| 目的 | 指令 |
|---|---|
| **開 Web 儀表板（最近一次）** | `uv run strix view` |
| 開指定的一次 | `uv run strix view 2026-11-14_https-example_1234` |
| 固定埠號、不自動開瀏覽器 | `uv run strix view --port 8080 --no-open` |
| 讓其他機器連進來 | `uv run strix view --host 0.0.0.0 --port 8080` |
| 列出本機所有執行 | `ls strix_runs` |
| 進去看某次結果 | `cd strix_runs\<執行名稱>` |

**結果檔案**

| 檔案 | 內容 |
|---|---|
| `penetration_test_report.md` | 完整報告 |
| `vulnerabilities/*.md` | 每個漏洞一份 |
| `vulnerabilities.json` | 結構化資料 |
| `findings.sarif` | CI／IDE 用 |
| `run.json` | 執行狀態與成本 |

---

## 5. 恢復先前掃描

```powershell
uv run strix --resume                    # 開選單挑一次
uv run strix --resume 2026-11-14_xxx     # 指定執行名稱
```

---

## 6. 開發與驗證（改程式碼後）

| 目的 | 指令 |
|---|---|
| Python 測試（CLI 相關） | `uv run pytest tests/test_cli_fail_on.py tests/test_main_launch.py -q` |
| Python 測試（全部） | `uv run pytest -q` |
| Python 語法檢查 | `python -m py_compile strix/interface/cli_args.py` |
| Go 建置（TUI） | `cd strix/interface/tui; go build ./...` |
| Go 測試 | `cd strix/interface/tui; go test ./...` |
| 前端建置（**改前端後必做**） | `cd strix/interface/viewer/frontend; npm run build` |
| 前端型別檢查 | `cd strix/interface/viewer/frontend; npx tsc --noEmit` |

> ⚠️ 前端改完一定要 `npm run build`，產物會寫入 `strix/interface/viewer/static/`，並要一起 commit。

---

## 7. 維護（同步上游、推送）

| 目的 | 指令 |
|---|---|
| 看目前分支 | `git branch` |
| 看改動 | `git status` |
| 提交 | `git add -A; git commit -m "說明"` |
| 推送（會推到 strix-zh-tw） | `git push origin main` |
| 同步 `zh-TW` 分支 | `git checkout zh-TW; git merge --ff-only main; git push origin zh-TW; git checkout main` |
| 抓上游更新 | `git fetch upstream` |
| 合併上游 | `git merge upstream/main` |

---

## 8. 排錯

| 症狀 | 先跑這個 |
|---|---|
| 掃不起來 | `docker version` / `docker images \| Select-String strix` |
| 鏡像沒拉完 | `docker pull ghcr.io/usestrix/strix-sandbox:1.4.1` |
| LLM 連線失敗 | `uv run strix --help`（確認能啟動）→ 檢查金鑰與模型名稱 |
| 磁碟滿 | `docker system df` → `docker system prune -a` |
| 中文亂碼 | `chcp 65001` |
| 腳本被擋 | `powershell -ExecutionPolicy Bypass -File .\start-strix.ps1 -Check` |

完整排錯：[TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 9. 常用組合（直接複製）

```powershell
# 第一次：環境檢查
cd C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh
.\start-strix.ps1 -Check

# 驗證漢化
uv run strix --help

# 快速掃描（省錢）
.\start-strix.ps1 -Target https://你的網站.com --scan-mode quick --max-budget 2

# 掃本機專案
uv run strix --target ./ --scan-mode quick --max-budget 2

# 看結果
uv run strix view

# 恢復上次掃描
uv run strix --resume
```

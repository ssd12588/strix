# 啟動器使用說明（Windows）

> 給不想記指令的人：雙擊 → 選任務 → 貼站點 → 開始。

---

## 安裝（只需一次）

在專案目錄執行：

```powershell
cd C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-shortcut.ps1
```

完成後桌面會出現 **「Strix漢化版」** 捷徑。

> 這支腳本會把正確的專案路徑寫進捷徑，所以**換電腦或改資料夾位置後，重跑一次就好**。

---

## 使用流程

雙擊桌面「Strix漢化版」，依序回答 5 個問題：

| 步驟 | 畫面 | 說明 |
|---|---|---|
| ① | 檢查環境 | 自動確認 `uv` 與 Docker；Docker 沒開會提醒 |
| ② | 選擇任務類型 | 列出 `instructions\*.md`，**新增檔案會自動出現** |
| ③ | 輸入站點 | 純網域（`example.com`）會做子網域收集；完整網址只測主站 |
| ④ | 掃描模式 | `quick`（5–10 分）／`standard`（約 30 分）／`deep`（1–4 小時） |
| ⑤ | 花費上限 | 美元。資產收集建議 1，漏洞稽核建議 2–5 |

確認後進入 Strix 的 TUI 介面。掃描完成會問你要不要開 Web 儀表板。

---

## 可選的任務類型

| 檔案 | 用途 | 目標建議填法 |
|---|---|---|
| `pii-audit.md` | PII 個資洩露、越權、API 安全、資料庫稽核 | 完整網址 `https://目標` |
| `recon-only.md` | 只做資產收集（子網域／來源 IP／端點），含 CDN、WAF、靜態資源排除規則 | 純網域 `目標.com` |
| （新增的 `.md`） | 你自訂的任務 | 依內容而定 |

### 自己新增任務類型

在 `instructions\` 放一個 `.md`，例如 `instructions\api-audit.md`，下次啟動就會出現在選單（第 3 個選項）。

---

## 常見問題

| 症狀 | 原因 | 解法 |
|---|---|---|
| 視窗一閃就消失 | 執行原則或路徑問題 | 開 PowerShell 手動跑：`powershell -ExecutionPolicy Bypass -File .\scripts\strix-launcher.ps1`，看完整錯誤 |
| 出現藍色 SmartScreen 警告 | 未簽章的 `.bat` | 點「更多資訊」→「仍要執行」 |
| 中文變亂碼 | 字型或編碼 | 用 Windows Terminal，字型選 Cascadia Mono；或執行 `chcp 65001` |
| 選單沒有我要的 md | 檔案不在 `instructions\` | 確認副檔名是 `.md`，且放在 `instructions\` 目錄 |
| `未連接終端機，改以無介面模式執行` | 該視窗不支援 TUI | 正常，功能一樣；或改用 Windows Terminal |

---

## 與命令列版的差別

| | `start-strix.ps1` | `scripts\strix-launcher.ps1` |
|---|---|---|
| 介面 | 命令列參數 | 互動選單 |
| 選指令檔 | 自己打 `--instruction-file` | 選單挑選 |
| 適用 | 熟練使用者、自動化 | 新手、臨時任務 |
| 位置 | 專案根目錄 | `scripts\`，可用桌面捷徑呼叫 |

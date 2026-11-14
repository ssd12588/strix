# Strix 漢化版 · 10 分鐘上手

> 本文件針對**繁體中文使用者**撰寫，帶你從零到第一次掃描完成。
> 若你要看完整功能說明，請見 [README](../README.md) 與 [`docs/`](../docs/)。

---

## 0. 先確認你需要的東西

| 項目 | 必要性 | 說明 |
|---|---|---|
| Docker | **必要** | Strix 的掃描在 Docker 沙箱內執行 |
| 一組 LLM API Key | **必要** | Strix 本身是「大腦的軀殼」，推理要靠 LLM |
| Python 3.12+ 或 `uv` | 選用 | 用 `uv tool install` 安裝時需要 |
| 終端機 | 必要 | Windows：PowerShell；macOS/Linux：Terminal |

---

## 1. 安裝 Docker

### Windows
1. 下載並安裝 [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. 安裝完**重新開機**（很重要，PATH 才會生效）
3. 開啟 Docker Desktop，等右下角顯示 **Engine running**
4. 驗證：
   ```powershell
   docker version
   ```
   能看到 `Server: Docker Engine` 就代表成功。

### macOS
```bash
brew install --cask docker          # 或安裝 OrbStack / Colima
open -a Docker
docker version
```

### Linux
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER       # 加完要重新登入
docker version
```

> ⚠️ 若出現 `permission denied while trying to connect to the Docker daemon socket`，代表群組設定尚未生效，請登出再登入。

---

## 2. 選一個 LLM（這是新手最容易卡住的一步）

Strix 支援 100 多種模型，但**不是每個都適合** —— 它需要具備「工具呼叫」能力的模型。

### 建議組合（依你的情況挑一個）

| 你的情況 | 建議設定 | 備註 |
|---|---|---|
| 想省錢、要中文能力好 | `deepseek/deepseek-v4-pro` | 中國廠商模型，中文理解好、單價低 |
| 想效果最好（官方推薦） | `openrouter/z-ai/glm-5.3` | 需要 OpenRouter 帳號 |
| 不想另外註冊服務 | `vercel_ai_gateway/zai/glm-5.3` | 需要 Vercel 帳號 |
| 已有 ChatGPT Plus/Pro | `chatgpt/gpt-5.4` | 走訂閱額度，見下方「用訂閱登入」 |
| 完全離線、資料不出門 | `ollama/qwen3-vl` | 需要本機 GPU，效果較弱 |
| 已有 OpenAI API | `openai/gpt-6.1-sol` | 需要 Daybreak 存取權才能做安全測試 |

### 不建議新手使用

- 參數 **小於 30B** 的本機模型：很容易無法正確呼叫工具，掃描會卡住
- 沒有工具呼叫能力的模型（純聊天模型）

### 關於「需要存取權」的模型

OpenAI / Anthropic / Google 的頂尖模型，用於安全測試需要額外申請：

| 供應商 | 需要申請 | 連結 |
|---|---|---|
| OpenAI | Daybreak（Trusted Access for Cyber） | <https://openai.com/daybreak/> |
| Anthropic | Cyber Verification Program（CVP） | <https://support.claude.com/en/articles/14604842-cyber-verification-program> |
| Gemini | Fairwind Program | <https://deepmind.google/fairwind-program/> |

沒有存取權時，模型會**拒絕**大多數攻擊性任務（不是你設定錯）。

---

## 3. 取得 API Key

以 **DeepSeek** 為例（最便宜、中文友善）：

1. 前往 <https://platform.deepseek.com>
2. 註冊 → 儲值少量金額（例如 ¥10 就夠測試很多次）
3. 左側 **API keys** → 建立 → 複製 `sk-...`

以 **OpenRouter** 為例：

1. 前往 <https://openrouter.ai>
2. 註冊 → **Credits** 儲值
3. **Keys** → Create Key → 複製 `sk-or-...`

---

## 4. 安裝 Strix 漢化版

### 方式 A：直接從原始碼執行（最快，推薦先試）

```powershell
# Windows PowerShell
git clone https://github.com/ssd12588/strix-zh-tw.git
cd strix
uv sync
```

macOS / Linux：
```bash
git clone https://github.com/ssd12588/strix-zh-tw.git
cd strix
uv sync
```

### 方式 B：安裝成全域指令

```powershell
uv tool install . --force
```

> ⚠️ 這個指令名 `strix` 與官方版相同，安裝後會**覆蓋**官方版。
> 想換回來：`uv tool uninstall strix-agent`

---

## 5. 設定環境變數

### Windows PowerShell（每次開新視窗都要設）

```powershell
$env:STRIX_LLM = "deepseek/deepseek-v4-pro"
$env:LLM_API_KEY = "sk-你的金鑰"
```

### macOS / Linux

```bash
export STRIX_LLM="deepseek/deepseek-v4-pro"
export LLM_API_KEY="sk-你的金鑰"
```

> 💡 不想每次重設？本文件同目錄提供 `start-strix.ps1`，
> 或用 Strix 內建設定檔（見第 8 節）。

### 用 ChatGPT 訂閱登入（不用 API Key）

```bash
strix auth login chatgpt
export STRIX_LLM="chatgpt/gpt-5.4"
```

---

## 6. 跑第一次掃描

```powershell
# 方式 A（從原始碼）
uv run strix --target https://example.com

# 方式 B（已安裝成指令）
strix --target https://example.com
```

**第一次執行會拉取沙箱 Docker 映像**（約數 GB），可能需要 5–15 分鐘，請耐心等。
之後每次掃描都是幾秒內開始。

想先確認安裝是否正常，可跑不耗點數的指令：

```powershell
uv run strix --help
```

看到「**用法: strix ...**」「**Strix 多代理網路安全滲透測試工具**」就代表成功。

---

## 7. 看結果

掃描完成後，結果會存在 `strix_runs/<執行名稱>/`。

### 在瀏覽器看（推薦）

```powershell
uv run strix view
```

會自動開瀏覽器，顯示中文儀表板：漏洞列表、嚴重度分布、代理關係圖。

### 直接看檔案

| 檔案 | 內容 |
|---|---|
| `penetration_test_report.md` | 完整滲透測試報告 |
| `vulnerabilities.json` | 結構化漏洞資料 |
| `findings.sarif` | 給 CI／IDE 用的 SARIF 格式 |
| `run.json` | 本次執行的狀態與成本 |

---

## 8. 讓設定不用每次重打

Strix 支援設定檔 `~/.strix/cli-config.json`：

```json
{
  "env": {
    "STRIX_LLM": "deepseek/deepseek-v4-pro",
    "LLM_API_KEY": "sk-你的金鑰"
  }
}
```

Windows 的路徑是 `C:\Users\你的帳號\.strix\cli-config.json`。

> ⚠️ 這個檔案含明文金鑰，請勿提交到 Git 或分享給他人。

---

## 9. 下一步

| 想做什麼 | 指令／文件 |
|---|---|
| 掃描本機專案 | `strix --target ./你的專案` |
| 只掃描、不開 TUI（CI 用） | `strix -n --target ./專案 --scan-mode quick` |
| 限制花費 | 加上 `--max-budget 5`（美元） |
| 提供帳號密碼 | 加上 `--instruction "登入用 user:pass"` |
| 換掃描深度 | `--scan-mode quick`／`standard`／`deep` |

完整選項：[`docs/usage/cli.mdx`](../docs/usage/cli.mdx)

---

## ⚠️ 使用前必讀

> **只對你擁有、或已取得明確書面授權的系統執行掃描。**
> 未經授權的滲透測試在大多數司法管轄區屬於違法行為，責任由使用者自負。

---

## 遇到問題？

請見 [常見錯誤排錯](TROUBLESHOOTING.md)。

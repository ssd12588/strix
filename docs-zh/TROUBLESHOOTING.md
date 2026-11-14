# 常見錯誤排錯（繁體中文）

> 本文件把 Strix 漢化版會顯示的**中文錯誤訊息**，對照回「真正的原因」與「解法」。
> 遇到看不懂的訊息，先按 `Ctrl+F` 搜尋你看到的那句話。

---

## 快速定位

| 你看到的訊息關鍵字 | 跳到 |
|---|---|
| Docker、映像、拉取 | [Docker 相關](#docker-相關) |
| 環境變數、STRIX_LLM、API_KEY | [設定相關](#設定相關) |
| LLM 連線、401、模型 | [模型與金鑰](#模型與金鑰) |
| 未連接終端機、TUI、介面 | [終端與介面](#終端與介面) |
| 參數、無法辨識、必填 | [指令參數](#指令參數) |
| 預算、回合、暫停 | [預算與回合](#預算與回合) |
| 亂碼、腳本無法執行 | [Windows 專屬問題](#windows-專屬問題) |

---

## Docker 相關

### `未安裝 Docker`
```
DOCKER NOT INSTALLED → 在你的 PATH 中找不到 'docker' 指令。
```
**原因**：Docker 沒裝，或裝了但終端機還沒讀到新的 PATH。

**解法**：
1. 安裝 [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. **完全關閉終端機再重開**（PATH 才生效）
3. 驗證：`docker version` 要能看到 `Server: Docker Engine`

---

### `Docker 無法使用`
```
無法連線到 <endpoint> 上的 Docker。
請確認 Docker 正在執行。若這個 shell 裡 `docker info` 能正常運作，
strix 會使用同一個 daemon；否則請設定 DOCKER_HOST。
```
**原因**：Docker Desktop 沒啟動，或目前使用者無權存取 daemon。

**解法**：
1. 開啟 Docker Desktop，等狀態變成 **Engine running**
2. 執行 `docker info` 測試：
   - 若 `docker info` 也失敗 → Docker 本身沒跑起來
   - 若 `docker info` 成功但 Strix 失敗 → 設定 `DOCKER_HOST`
3. Linux 額外檢查：`sudo usermod -aG docker $USER` 後**重新登入**

---

### `映像拉取失敗`
```
無法下載: ghcr.io/usestrix/strix-sandbox:x.x.x
```
**原因**：網路中斷、磁碟空間不足、或無法連上 ghcr.io。

**解法**：
```bash
docker pull ghcr.io/usestrix/strix-sandbox:1.4.1   # 手動先拉，看真實錯誤
```
- 若卡在「Waiting」很久 → 可能是網路問題，掛上 proxy 或換網路
- 若顯示 `no space left on device` → 清磁碟：`docker system prune -a`
- 若無法連線 ghcr.io，需先設定 Docker registry mirror

---

## 設定相關

### `缺少必要的環境變數`
```
缺少必要的環境變數
• STRIX_LLM 未設定
```
**原因**：沒有指定要用哪個模型。

**解法**：
```powershell
$env:STRIX_LLM = "deepseek/deepseek-v4-pro"
```
或寫進 `~/.strix/cli-config.json`（見 [QUICKSTART 第 8 節](QUICKSTART.md#8-讓設定不用每次重打)）。

---

### `未知的模型名稱`
```
未知的模型名稱
'gpt-4' 不是已知的 OpenAI 模型。未帶供應商前綴的名稱預設會送到 OpenAI。
```
**原因**：模型名稱少了供應商前綴，Strix 會預設當成 OpenAI 模型。

**解法**：加上前綴。

| ❌ 錯 | ✅ 對 |
|---|---|
| `deepseek-v4-pro` | `deepseek/deepseek-v4-pro` |
| `glm-5.3` | `openrouter/z-ai/glm-5.3` |
| `claude-opus-5-5` | `anthropic/claude-opus-5-5` |

---

### `找不到設定檔` / `設定檔的 JSON 格式無效`
**原因**：`--config` 指定的路徑錯誤，或 JSON 有語法錯誤（多一個逗號也算）。

**解法**：用編輯器檢查 JSON，或先拿掉 `--config` 改用環境變數。

---

## 模型與金鑰

### `LLM 連線失敗`
```
LLM CONNECTION FAILED
無法建立與語言模型的連線。
請檢查你的設定後再試一次。
錯誤: <原始錯誤>
```
**這是最常見的錯誤，原因不只一種**，請看 `錯誤:` 後面那行：

| 原始錯誤包含 | 原因 | 解法 |
|---|---|---|
| `401` / `Unauthorized` / `invalid api key` | 金鑰錯誤或已失效 | 重新複製金鑰，確認沒有多餘空白 |
| `402` / `Insufficient Balance` | 帳戶餘額不足 | 到供應商後台儲值 |
| `403` / `forbidden` | 金鑰權限不足 | 檢查 Key 權限設定 |
| `404` / `model not found` | 模型名稱錯 | 對照 [供應商文件](../docs/llm-providers/overview.mdx) |
| `429` / `rate limit` | 請求太頻繁 | 等一下，或升級方案 |
| `timeout` / `Connection` | 網路不通 | 檢查 proxy／防火牆 |
| `blocked` / `refused` / `safety` | **模型拒絕執行攻擊性任務** | 見下方「模型拒絕」 |

---

### 模型拒絕執行（不是你的錯）

**症狀**：金鑰正確、餘額足夠，但一執行就說無法協助、或連線失敗。

**原因**：OpenAI / Anthropic / Google 對「安全測試」有額外授權要求。

**解法**：

| 供應商 | 需要申請 |
|---|---|
| OpenAI | [Daybreak](https://openai.com/daybreak/) |
| Anthropic | [CVP](https://support.claude.com/en/articles/14604842-cyber-verification-program) |
| Gemini | [Fairwind](https://deepmind.google/fairwind-program/) |

**沒有存取權時的替代方案**：改用不設此限制的模型，例如
`deepseek/deepseek-v4-pro`、`openrouter/z-ai/glm-5.3`、`moonshot/kimi-k3.1-pro`。

---

### `此模型不在訂閱方案中` / `你的 ChatGPT 登入已過期`
```
你的 ChatGPT 登入已過期或被撤銷。請重新登入：
  strix auth login chatgpt
```
**解法**：
```bash
strix auth login chatgpt     # 重新登入
strix auth status            # 確認狀態
```
若顯示「模型不在方案中」→ 換成方案內含的模型，例如 `chatgpt/gpt-5.4`。

---

## 終端與介面

### `未連接終端機`
```
未連接終端機
互動介面需要終端機，但沒有提供任何目標。
請加上 -t <目標> -n 以無介面模式執行。
```
**原因**：你在沒有互動終端機的環境（CI、`nohup`、管道、IDE 內建輸出視窗）執行，但沒給目標。

**解法**：
```bash
strix -n --target https://example.com
```

---

### `未連接終端機，改以無介面模式執行（等同 -n）。`
**這是提示，不是錯誤。** Strix 偵測不到終端機，自動切成無介面模式繼續執行。

若你**想要** TUI 但沒出現 → 改用「真正的終端機」：

| 環境 | 做法 |
|---|---|
| VS Code | 用「Terminal → New Terminal」，不要用 OUTPUT 面板 |
| Windows | 用 Windows Terminal / PowerShell 視窗 |
| CI | 本來就不會有 TUI，加 `-n` 即可 |

---

### `互動介面已停止`
```
Bubble Tea TUI exited with status 1。
若 Strix 在沒有終端機的環境執行（CI、nohup、管線），請加上 -n 以無介面模式執行。
```
**解法**：加上 `-n` 改用無介面模式；或換成支援 TUI 的終端機（勿用 IDE 的輸出面板）。

---

### `互動式設定無法使用`
**原因**：TUI 的附屬程式（Go sidecar）缺失或無法啟動。

**解法**：
```bash
cd strix/interface/tui; go build ./...; cd ../../..
uv run strix
```
若用 `uv tool install` 安裝，請確認安裝的是**漢化版**而非舊的官方版：
`uv tool uninstall strix-agent` 後重裝。

---

### TUI 顯示亂碼 / 排版錯位
**原因**：終端機字型不支援中文，或沒有等寬字型。

**解法**：
- Windows Terminal：設定 → 外觀 → 字型選 **Cascadia Mono** 或 **Microsoft JhengHei**
- 確認終端機寬度至少 100 欄（中文佔 2 格，太窄會擠壓排版）

---

## 指令參數

### `缺少必要參數: -t/--target 或 --target-list`
**解法**：至少給一個目標。
```bash
strix --target https://example.com
strix --target ./你的專案
strix --target-list ./targets.txt
```

---

### `無法辨識的參數: --xxx`
**原因**：參數打錯，或你的版本不支援。

**解法**：`strix --help` 查看可用參數（本漢化版已是中文）。

---

### `無效的選擇: 'xxx'（可選: ...）`
**原因**：列舉型參數給錯值。

| 參數 | 可選值 |
|---|---|
| `--scan-mode` | `quick`、`standard`、`deep` |
| `--scope-mode` | `auto`、`diff`、`full` |
| `--fail-on` | `critical`、`high`、`medium`、`low`、`info` |

---

### `--fail-on 僅適用於無介面執行`
**原因**：`--fail-on` 只在 CI／無介面模式有意義。

**解法**：加上 `-n`。
```bash
strix -n --target ./ --fail-on high
```

---

### `不能同時指定 --instruction 與 --instruction-file`
**解法**：擇一使用；長指令請寫成檔案再引用。

---

## 預算與回合

### `已達預算上限`（TUI 顯示）
**這是正常行為**：花費達到 `--max-budget` 時，Strix 會**暫停**而不是中斷。

**解法**：在 TUI 輸入框送出任何訊息即可繼續（會以相同金額延長上限），或按 `ctrl-q` 離開。

---

### 掃描中途停止 / 代理被強制結束
**原因**：達到 `--max-turns`（每個代理的回合上限，預設 500）。

**解法**：
```bash
strix --target ./專案 --max-turns 800
```

---

## Windows 專屬問題

### 中文亂碼（顯示 `????` 或方塊）
PowerShell 預設編碼可能不是 UTF-8：

```powershell
chcp 65001
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = "1"
```

---

### 執行 `.ps1` 腳本被阻擋
```
無法載入檔案 ... 因為這個系統上已停用指令碼執行
```
**解法**（擇一）：
```powershell
# 只對本次有效
powershell -ExecutionPolicy Bypass -File .\start-strix.ps1

# 永久設定（僅限目前使用者）
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

### 路徑含中文或空格導致錯誤
**原因**：某些 Docker／Go 工具對非 ASCII 路徑支援不佳。

**解法**：把專案複製到純英文路徑再執行，例如 `C:\dev\strix`，
而不是 `C:\Users\阿樂\...\strix`。

---

### Docker Desktop 一直停在「Starting」
**解法**：
1. 確認 BIOS 已開啟虛擬化（VT-x / AMD-V）
2. 確認已安裝 WSL2：`wsl --update`
3. Docker Desktop → Settings → General → 勾選 **Use the WSL 2 based engine**
4. 重開機

---

## 還是解決不了？

請準備以下資訊，再開 Issue：

```bash
strix --version
docker version
docker info
```

以及：
- 完整錯誤訊息（**注意先遮蔽 API Key**）
- 你用的 `STRIX_LLM` 值
- 作業系統版本

→ [回報問題](https://github.com/ssd12588/strix/issues/new)

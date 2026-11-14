<p align="center">
  <a href="https://strix.ai/">
    <img src="https://github.com/usestrix/.github/raw/main/imgs/cover.png" alt="Strix Banner" width="100%">
  </a>
</p>

<div align="center">

# Strix 漢化版

### 開源 AI 滲透測試工具（繁體中文漢化版）。自主運作的 AI 駭客，替你找出並修補應用程式弱點。

<br/>


<a href="https://docs.strix.ai"><img src="https://img.shields.io/badge/Docs-docs.strix.ai-2b9246?style=for-the-badge&logo=gitbook&logoColor=white" alt="Docs"></a>
<a href="https://strix.ai"><img src="https://img.shields.io/badge/Website-strix.ai-f0f0f0?style=for-the-badge&logoColor=000000" alt="Website"></a>
[![](https://dcbadge.limes.pink/api/server/strix-ai)](https://discord.gg/strix-ai)

<a href="https://app.strix.ai?utm_source=github&utm_medium=readme&utm_content=badge_cloud"><img src="https://img.shields.io/badge/Strix%20Cloud-app.strix.ai-2b9246?style=for-the-badge&logoColor=white" alt="Strix Cloud"></a>
<a href="https://strix.ai/demo?utm_source=github&utm_medium=readme&utm_content=badge_demo"><img src="https://img.shields.io/badge/Try%20Strix%20Enterprise-555555?style=for-the-badge&logoColor=white" alt="Try Strix Enterprise"></a>

<a href="https://github.com/usestrix/strix"><img src="https://img.shields.io/github/stars/usestrix/strix?style=flat-square" alt="GitHub Stars"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-3b82f6?style=flat-square" alt="License"></a>
<a href="https://pypi.org/project/strix-agent/"><img src="https://img.shields.io/pypi/v/strix-agent?style=flat-square" alt="PyPI Version"></a>


<a href="https://discord.gg/strix-ai"><img src="https://github.com/usestrix/.github/raw/main/imgs/Discord.png" height="40" alt="Join Discord"></a>
<a href="https://x.com/strix_ai"><img src="https://github.com/usestrix/.github/raw/main/imgs/X.png" height="40" alt="Follow on X"></a>


<a href="https://trendshift.io/repositories/15362?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-15362" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/15362/weekly" alt="usestrix%2Fstrix | Trendshift" width="250" height="55"/></a>
<a href="https://trendshift.io/repositories/15362" target="_blank"><img src="https://trendshift.io/api/badge/repositories/15362" alt="usestrix/strix | Trendshift" width="250" height="55"/></a>

</div>


> [!TIP]
> **新功能！** Strix 可無縫整合 GitHub Actions 與 CI/CD 流程。每次 Pull Request 自動掃描漏洞，在不安全的程式碼進入正式環境前就攔下 —— [免設定立即開始](https://app.strix.ai?utm_source=github&utm_medium=readme&utm_content=tip_ci)。

---

## 關於本漢化版

**本漢化版由 [阿樂](https://github.com/ssd12588) 負責繁體中文漢化與維護。**

- 本倉庫是 [usestrix/strix](https://github.com/usestrix/strix) 的**繁體中文漢化版**，依 Apache-2.0 授權散布，原始版權聲明與 [`LICENSE`](LICENSE) 均完整保留。
- **已漢化**：終端機（CLI）說明與錯誤訊息、TUI 互動介面、`strix view` 的 Web 檢視器介面、本 README。
- **尚未漢化**：`docs/` 文件站。
- **刻意不改**：掃描引擎邏輯、代理提示詞（`strix/agents/prompts`）與技能內容（`skills/`）維持英文，以確保 AI 行為與上游一致。
- 與上游同步：

  ```bash
  git remote add upstream https://github.com/usestrix/strix.git
  git fetch upstream
  git merge upstream/main
  ```

- 漢化相關問題請在本倉庫開 issue，無需打擾上游維護者。

---


## Strix 概觀

Strix 是一群自主運作的 AI 滲透測試代理，行為就像真正的駭客 —— 它會動態執行程式碼、找出漏洞，並透過實際的概念驗證（PoC）確認漏洞真的可利用。它為需要快速且準確安全測試的開發者與安全團隊而打造，免去人工滲透測試的沉重負擔，也沒有靜態分析工具常見的誤報。

**核心能力：**

- **完整滲透測試工具箱** —— 偵察、利用、驗證一應俱全
- **多代理協同運作** —— 多個 AI 滲透測試員組隊合作、彈性擴展
- **真實利用驗證** —— 產出可運作的 PoC，而不是舊式掃描器的大量誤報
- **開發者優先的 CLI** —— 提供可執行的發現與修補指引
- **自動修補與報告** —— 產生修補程式與符合法規要求的滲透測試報告


<br>


<div align="center">
  <a href="https://strix.ai">
    <img src=".github/screenshot.png" alt="Strix Demo" width="1000" style="border-radius: 16px;">
  </a>
</div>


## 適用場景

- **應用程式安全測試** —— 偵測並驗證應用程式中的重大漏洞
- **快速滲透測試** —— 幾小時內完成滲透測試（而非幾週），並附上合規報告
- **Bug Bounty 自動化** —— 自動化漏洞賞金研究並產生 PoC，加快回報速度
- **CI/CD 整合** —— 在 CI/CD 中執行測試，於上線前攔下漏洞

## 🚀 快速開始

**先決條件：**
- Docker（需正在執行）
- 任一[支援的供應商](https://docs.strix.ai/llm-providers/overview)的 LLM API 金鑰（OpenAI、Anthropic、Google 等）

### 安裝與第一次掃描

```bash
# 安裝 Strix
curl -sSL https://strix.ai/install | bash

# 設定你的 AI 供應商
export STRIX_LLM="vercel_ai_gateway/zai/glm-5.3"   # Vercel AI Gateway
# export STRIX_LLM="openrouter/z-ai/glm-5.3"       # OpenRouter
export LLM_API_KEY="your-api-key"

# 執行第一次安全評估
strix --target ./app-directory
```

> [!NOTE]
> 第一次執行會自動拉取沙箱 Docker 映像。結果會儲存在 `strix_runs/<run-name>`

### 更新

```bash
# 將獨立二進位檔自我更新到最新版本
strix --update

# ……或重新執行安裝腳本
curl -sSL https://strix.ai/install | bash
```

用 pipx、uv 或 pip 安裝的嗎？`strix --update` 會改為印出對應的升級指令（`pipx upgrade strix-agent`、`uv tool upgrade strix-agent`、`pip install --upgrade strix-agent`）。有新版本時，Strix 也會顯示含正確指令的提示。

---

## 執行 Strix 的方式

- **開源自架** —— 免費，在本機以 Docker 搭配自己的 LLM 金鑰執行。[快速開始](https://docs.strix.ai/quickstart)
- **Strix Cloud** —— 免設定、經驗證的發現、一鍵自動修補與 PR 審查。[執行滲透測試 →](https://app.strix.ai?intent=pentest&utm_source=github&utm_medium=readme&utm_content=table_cloud)
- **企業版** —— SSO、符合法規的報告、VPC 或自架部署。[試用 Strix Enterprise →](https://strix.ai/demo?utm_source=github&utm_medium=readme&utm_content=table_demo)

---

## ☁️ Strix Cloud

在 **[app.strix.ai](https://app.strix.ai?utm_source=github&utm_medium=readme&utm_content=cloud_heading)** 試用 Strix 全端滲透測試平台 —— 免費註冊、連接你的儲存庫與網域，幾分鐘內就能啟動一次滲透測試。

- **含 PoC 的驗證發現** —— 每個漏洞都附可運作的利用程式與重現步驟
- **一鍵自動修補** —— AI 產生的安全修補，直接變成可合併的 Pull Request
- **持續滲透測試** —— 全天候弱點掃描，跟得上你的部署節奏
- **DevSecOps 整合** —— GitHub、GitLab、Bitbucket、Slack、Jira、Linear 與 CI/CD 流程
- **持續學習** —— AI 會累積過去的發現、適應你的程式庫，並逐步降低誤報

[**執行滲透測試 →**](https://app.strix.ai?intent=pentest&utm_source=github&utm_medium=readme&utm_content=cloud_cta)

## 🏢 企業版

以企業級管控取得相同的 Strix 體驗：SSO（SAML/OIDC）、符合法規要求的滲透測試報告（SOC 2、ISO 27001、PCI DSS）、專屬支援與 SLA、自訂部署方式（VPC 或自架）、BYOK 模型支援，以及針對你的環境調校的 AI 滲透測試代理。

[**試用 Strix Enterprise →**](https://strix.ai/demo?utm_source=github&utm_medium=readme&utm_content=enterprise_cta)

---

## 🤖 從你的程式開發代理使用 Strix

Strix 已為代理做好準備。讓 Claude Code、Cursor、Codex，或任何[相容 SKILL.md](https://agentskills.io) 的代理具備執行滲透測試、修補發現與設定 CI 掃描的能力：

```bash
npx skills add usestrix/strix
```

這會安裝九項技能，涵蓋執行滲透測試、修補發現與 CI 掃描，對象包括程式碼、Web 應用、API 與 OWASP Top 10。代理可使用本機 CLI，或改用同一引擎的受管雲端服務。

快速參考請見 [`AGENTS.md`](AGENTS.md)，CLI 說明見 [docs.strix.ai/llms.txt](https://docs.strix.ai/llms.txt)，API 說明見 [docs.app.strix.ai](https://docs.app.strix.ai)。

---

## ✨ 功能特色

### 代理式滲透測試工具

Strix 代理配備完整的攻擊性安全工具箱 —— 與專業滲透測試人員、道德駭客所用的是同一套工具：

- **HTTP 攔截代理** —— 透過 Caido 完整操作與分析請求／回應
- **瀏覽器利用** —— 自動化瀏覽器，用於測試 XSS、CSRF、點擊劫持與認證繞過流程
- **Shell 與指令執行** —— 互動式終端機，用於開發利用程式與後滲透作業
- **自訂利用執行環境** —— Python 沙箱，用於撰寫與驗證 PoC 利用程式
- **偵察與 OSINT** —— 自動化攻擊面測繪、子網域列舉與指紋辨識
- **靜態與動態程式碼分析** —— SAST + DAST，涵蓋完整的應用程式安全測試
- **漏洞知識庫** —— 結構化發現，附 CVSS 評分與 OWASP 分類

### 全方位漏洞掃描

Strix 能識別、驗證並利用 OWASP Top 10 及其他類型的大量安全弱點：

- **存取控制失效** —— IDOR、權限提升、認證繞過
- **注入攻擊** —— SQL 注入、NoSQL 注入、作業系統指令注入、SSTI
- **伺服器端弱點** —— SSRF、XXE、不安全的反序列化、RCE
- **用戶端攻擊** —— XSS（儲存型／反射型／DOM）、原型污染、CSRF
- **業務邏輯缺陷** —— 競態條件、付款金額竄改、流程繞過
- **認證與工作階段** —— JWT 攻擊、工作階段固定、憑證填充向量
- **基礎設施與雲端** —— 錯誤設定、曝露的服務、雲端安全問題
- **API 安全** —— 認證失效、大量賦值（mass assignment）、速率限制繞過

### 代理關係圖（多代理滲透測試）

進階的多代理協同運作，實現完整的自動化滲透測試：

- **分散式滲透測試** —— 專責偵察、利用與後滲透的 AI 代理
- **可擴展的安全測試** —— 對多個目標平行執行，快速且全面地涵蓋
- **動態協調** —— 代理會共享發現、串接漏洞，像紅隊一樣合作

---

## 🖥️ 本機 Web 檢視器

每次掃描在執行過程中都會把結果寫入磁碟。用一行指令就能在本機儀表板中檢視：

```bash
# 開啟最近一次執行
strix view

# ……或以名稱開啟指定的一次執行
strix view my-run-name

# 在所有 IPv4 介面的固定連接埠上公開檢視器
strix view --host 0.0.0.0 --port 8080 --no-open
```

儀表板會顯示漏洞發現、代理團隊的即時關係圖與過去的執行紀錄。所有資料都留在你的機器上，介面也已經預先建置好。`strix view` 會綁定 `127.0.0.1` 並印出帶有權杖的連結，持有該連結即可存取這次執行，請謹慎分享。

選項說明與如何從其他機器連上檢視器，請見[檢視器文件](https://docs.strix.ai/usage/viewer)。

---

## 使用範例

### 基本用法

```bash
# 掃描本機程式庫
strix --target ./app-directory

# 對 GitHub 儲存庫做安全檢視
strix --target https://github.com/org/repo

# 黑箱 Web 應用程式評估
strix --target https://your-app.com
```

### API 測試（OpenAPI / Swagger / Postman）

把 Strix 指向 API 契約，它就會逐一測試所有已宣告的端點，不必靠爬蟲自行探索。請把規格檔與實際的 base URL 一起提供，代理才知道要把流量送到哪裡：

```bash
# OpenAPI / Swagger 檔案、Postman 匯出檔，或以 id 指定的線上 collection
strix --target ./openapi.yaml --target https://api.your-app.com
strix --target postman://<collection-uuid> --target https://api.your-app.com
```


### 進階測試情境

```bash
# 灰箱認證測試
strix --target https://your-app.com --instruction "Perform authenticated testing using credentials: user:pass"

# 多目標測試（原始碼 + 已部署的應用程式）
strix -t https://github.com/org/app -t https://your-app.com

# 從檔案讀取目標，每行一個（略過空行與註解行）
strix --target-list ./targets.txt
```

所有選項（掃描模式、diff 範圍、指令檔、預算等）請見 [CLI 參考](https://docs.strix.ai/usage/cli)。

### 無介面模式

使用 `-n/--non-interactive` 旗標，就能以程式化方式執行 Strix 而不開啟互動介面 —— 非常適合伺服器與自動化工作。CLI 會即時印出漏洞發現，並在結束前輸出最終報告。若發現漏洞，結束碼非零。

```bash
strix -n --target https://your-app.com
```

### CI/CD（GitHub Actions）

你可以把 Strix 加進流程，透過輕量的 GitHub Actions 工作流程在 Pull Request 上執行安全測試：

```yaml
name: strix-penetration-test

on:
  pull_request:

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Install Strix
        run: curl -sSL https://strix.ai/install | bash

      - name: Run Strix
        env:
          STRIX_LLM: ${{ secrets.STRIX_LLM }}
          LLM_API_KEY: ${{ secrets.LLM_API_KEY }}

        run: strix -n -t ./ --scan-mode quick
```

> [!TIP]
> 在 CI 的 Pull Request 執行中，Strix 會自動把快速檢視的範圍限定在變更的檔案，這正是上面的
> checkout 需要抓取完整歷史的原因。詳情請見
> [CI/CD 文件](https://docs.strix.ai/integrations/github-actions)。

### 設定

```bash
export STRIX_LLM="vercel_ai_gateway/zai/glm-5.3"   # Vercel AI Gateway
# export STRIX_LLM="openrouter/z-ai/glm-5.3"       # OpenRouter
export LLM_API_KEY="your-api-key"

# 選用
export LLM_API_BASE="your-api-base-url"  # 使用本機模型時（例如 Ollama、LMStudio）
```

> [!NOTE]
> Strix 會自動把設定存到 `~/.strix/cli-config.json`，所以不必每次執行都重新輸入。
> 所有環境變數請見[設定參考](https://docs.strix.ai/advanced/configuration)。

#### 使用 ChatGPT 訂閱登入

除了按用量計費的 API 金鑰，你也可以用 ChatGPT Plus/Pro 訂閱來執行 Strix：

```bash
strix auth login chatgpt             # 以你的 ChatGPT 帳號登入
export STRIX_LLM="chatgpt/gpt-5.4"   # chatgpt/<model> 會走訂閱額度
strix auth status                    # 顯示目前登入狀態；logout 可清除
```

#### 使用受管平台：`strix cloud`

在終端機直接對 [app.strix.ai](https://app.strix.ai) 執行掃描，不需要 Docker 或 LLM 金鑰：

```bash
strix cloud login                                  # 瀏覽器登入，每次安裝一組憑證
strix cloud scans start --source . --yes --wait    # 掃描本機程式碼，並同意上傳
strix cloud scans start --engagement-type live_test --domain-ids <uuid> --wait
strix cloud vulns list --severity critical
```

每個 [REST API](https://docs.app.strix.ai) 操作都有對應的 `strix cloud <resource> <verb>` 指令。執行 `strix cloud` 可列出所有資源，對某個資源加上 `help` 則會列出它的動詞。當 stdout 不是終端機，或你加上 `--json` 時，輸出為 JSON。二進位下載是例外：請直接重導原始位元組，或結合 `--output FILE --json` 取得下載中介資料。

範圍（scopes）、工作區、帳務與來源上傳選項，請見[雲端 CLI 文件](https://docs.strix.ai/cloud/cli)。

#### 連接你自己的 MCP 伺服器

Strix 可以連接你列出的 Model Context Protocol（MCP）伺服器，並在執行期間把它們的工具提供給代理使用。建立 `~/.strix/mcp-servers.json`，內容是本機 `stdio` 或遠端 `http` 伺服器的 JSON 清單：

```json
[
  {
    "name": "github",
    "transport": "http",
    "url": "https://api.githubcopilot.com/mcp/",
    "auth": { "kind": "bearer", "token": "your-token" },
    "allowed_tools": ["list_issues"]
  }
]
```

每個伺服器的工具都會以 `name` 加上命名空間，例如 `github_list_issues`。完整結構、工具過濾與 `stdio` 伺服器說明，請見 [MCP 文件](https://docs.strix.ai/integrations/mcp)。

**建議模型（效果最佳）：**

- [Z.ai GLM-5.3（Vercel AI Gateway）](https://vercel.com/ai-gateway/models/glm-5.3) - `vercel_ai_gateway/zai/glm-5.3`（建議）
- [Z.ai GLM-5.3（OpenRouter）](https://openrouter.ai/z-ai/glm-5.3) - `openrouter/z-ai/glm-5.3`（建議）
- [DeepSeek V4.1 Flash（OpenRouter）](https://openrouter.ai/deepseek/deepseek-v4.1-flash-1017) - `openrouter/deepseek/deepseek-v4.1-flash-1017`
- [OpenAI GPT-6.1 Sol](https://openai.com/api/) - `openai/gpt-6.1-sol`（需具備 [Daybreak](https://openai.com/daybreak/) 存取權）
- [Anthropic Claude Opus 5.5](https://claude.com/platform/api) - `anthropic/claude-opus-5-5`（需具備 [CVP](https://support.claude.com/en/articles/14604842-cyber-verification-program) 存取權）
- [Google Gemini 4 Argon](https://cloud.google.com/vertex-ai) - `vertex_ai/gemini-4-argon`（需具備 [Fairwind](https://deepmind.google/fairwind-program/) 存取權）
- [DeepSeek V4 Pro](https://platform.deepseek.com) - `deepseek/deepseek-v4-pro`
- [Moonshot Kimi K3.1 Pro](https://platform.kimi.ai) - `moonshot/kimi-k3.1-pro`

所有支援的供應商（含 Vertex AI、Bedrock、Azure 與本機模型）請見 [LLM 供應商文件](https://docs.strix.ai/llm-providers/overview)。

## 文件

完整文件位於 **[docs.strix.ai](https://docs.strix.ai)**，內容包括使用方式、CI/CD 整合、技能（skills）與進階設定的詳細指南。

## 參與貢獻

我們歡迎程式碼、文件與新技能的貢獻 —— 請先閱讀[貢獻指南](https://docs.strix.ai/contributing)，或直接開 [Pull Request](https://github.com/usestrix/strix/pulls)／[Issue](https://github.com/usestrix/strix/issues)。

## 加入社群

有問題？找到 bug？想貢獻？**[加入我們的 Discord！](https://discord.gg/strix-ai)**

## 支持這個專案

**喜歡 Strix 嗎？** 在 GitHub 給我們一個 ⭐！（漢化相關問題請在本倉庫開 issue）

## 致謝

Strix 建立於眾多優秀開源專案的成果之上，包括 [LiteLLM](https://github.com/BerriAI/litellm)、[Caido](https://github.com/caido/caido)、[Nuclei](https://github.com/projectdiscovery/nuclei)、[Playwright](https://github.com/microsoft/playwright) 與 [Bubble Tea](https://github.com/charmbracelet/bubbletea)。由衷感謝這些專案的維護者！


> [!WARNING]
> **僅限授權使用。** Strix 會主動測試你指定的目標，因此請僅對你擁有、或已取得**明確書面授權**的系統執行，並遵守約定的測試範圍。在大多數司法管轄區，未經授權的測試屬於違法行為。
> 取得授權與遵守法律完全由你自行負責。Strix 依「現狀」提供，對不當使用不負任何擔保或賠償責任。

</div>

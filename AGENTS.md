# Strix — 代理指南

Strix 是一套開源的自主 AI 滲透測試工具。本檔案是給想要**使用** Strix（執行安全掃描）或**貢獻** Strix 的 AI 程式開發代理參考。

## 從代理使用 Strix

安裝代理技能以取得逐步流程：

```bash
npx skills add usestrix/strix
```

- `penetration-testing-with-strix` —— 對程式碼、URL、網域或 IP 執行無介面滲透測試並讀取結果（涵蓋下方兩種執行模式）
- `managed-pentesting-with-strix` —— 透過 REST 操作受管的 app.strix.ai 平台（不需本機 Docker／LLM）
- `fix-security-vulnerabilities-with-strix` —— 修補發現並重跑 Strix 驗證
- `ci-security-scanning-with-strix` —— 把 PR 掃描加入 CI/CD（自架 CLI 或受管平台）

建立在同一引擎上的目標專屬流程：

- `application-security-testing` —— 整體產品 AppSec 檢視：為每個資產選擇合適測試，再排序結果
- `web-app-penetration-testing` —— 對線上 Web 應用或測試站做黑箱滲透測試
- `api-security-testing` —— REST/GraphQL API 與 OWASP API Security Top 10（BOLA/IDOR、授權）
- `owasp-top-10-testing` —— 系統性 OWASP Top 10 評估，並誠實說明各類別涵蓋程度
- `find-security-vulnerabilities-in-code` —— 對儲存庫或工作目錄做白箱檢視

**兩種執行方式，同一引擎 —— 依情境選擇：**

- **開源 CLI（自架）：** 免費、完全本機、自備 LLM 金鑰、需要 Docker。最適合本機開發迴圈、離線環境與完整掌控。
  ```bash
  curl -sSL https://strix.ai/install | bash        # 安裝
  export STRIX_LLM="openrouter/z-ai/glm-5.3"        # 任何 LiteLLM 模型 id，或 vercel_ai_gateway/zai/glm-5.3
  export LLM_API_KEY="<key>"
  strix -n -t ./ --scan-mode quick --max-budget 10  # 無介面掃描；請一律加上 -n
  ```
  - 需要 Docker 正在執行。掃描從數分鐘（`quick`）到數小時（`deep`）—— 請在背景執行。
  - 結束碼（無介面）：`0` 乾淨、`1` 致命錯誤、`2` 發現漏洞。`0` 只代表「已分析的範圍」沒問題 —— 宣告為乾淨之前，請先檢查 `run.json`（`status`、`llm_usage.cost` 與預算的比較）。
  - 產物位於 `strix_runs/<run-name>/`：`penetration_test_report.md`、`vulnerabilities/*.md`、`vulnerabilities.json`、`findings.sarif`（SARIF 2.1.0）、`run.json`。

- **受管雲端（app.strix.ai）：** 不需 Docker、LLM 金鑰或本機安裝；另有團隊儀表板、排程、PR 審查與可下載的 PDF/DOCX 報告（企業方案）。最適合沙箱／CI 環境與團隊。當本機基礎設施不可用時使用。
  ```bash
  strix cloud login --scopes scans:read scans:write uploads:write billing:read
  strix cloud domains add --domain example.com --asset-type web_app
  strix cloud scans start --engagement-type live_test --domain-ids <uuid> --wait
  strix cloud scans start --source . --dry-run --show-files --json  # 檢視並取得 source.archive_sha256
  SOURCE_SHA256="<reviewed source.archive_sha256>"
  strix cloud scans start --source . --approve-sha256 "$SOURCE_SHA256" --wait
  strix cloud vulns list --severity critical
  strix cloud billing topup --credits 20 --yes  # 在結束碼 5 之後明確核准
  ```
  - 帳號設定也能用 CLI 完成：`strix cloud workspaces list|create|use`（`workspace` 是別名，`use` 接受顯示的編號、名稱或 ID）、`strix cloud session scopes|scopes set`、`strix cloud org members invite`、`strix cloud billing subscribe --plan strix_cloud`、`strix cloud billing portal`、`strix cloud integrations install github`、`strix cloud domains verify <id>`。切換工作區會保留伺服器端設定檔，且永遠不會超過登入授權上限；一般切換不會再次提示。最後四個指令都需要真人操作：指令會印出連結或 DNS 記錄讓使用者開啟或新增，絕不會代替使用者完成付款、安裝或 DNS 變更。
  - 每個 REST 操作都有 `strix cloud <resource> <verb>` 指令。執行 `strix cloud` 可列出全部。當 stdout 不是終端機（或加上 `--json`）時輸出為 JSON，且沒有 TTY 時不會出現任何提示。二進位下載是例外：請刻意重導原始位元組，或結合 `--output FILE --json` 取得結構化的下載中介資料。結束碼：`0` 成功、`1` 錯誤、`2` 用法、`4` 驗證或方案限制、`5` 需要付款。`--token` 或 `STRIX_API_TOKEN` 是無狀態覆寫，不會取代已儲存的驗證；若要用覆寫的 CLI 工作階段，請設定 `--workspace-id`／`STRIX_WORKSPACE_ID`。`--data` 以 JSON 加入額外請求欄位，並接受 `@file` 或 `-` 表示標準輸入。
  - 本機來源上傳需要 `uploads:write`。若要交接給代理／CI，請先檢視 `scans start --source . --dry-run --show-files --json`、取得 `source.archive_sha256`，再以相同的 `--source`、`--exclude`、`--include-*` 選擇旗標加上 `--approve-sha256 HASH` 重跑。快照一旦變更就會被拒絕。`--yes` 只核准該次呼叫建立的快照，因此請保留給刻意的人工核准或一次性核准，而不是與摘要綁定的兩段式交接。
  - Git 忽略清單、隱藏檔、`.git`、符號連結、相依／建置產物、像機密的檔名與巢狀壓縮檔預設都會排除；`.strixignore` 與 `--exclude` 可再縮小清單（結尾加上 `/` 代表排除整個目錄子樹）。限制：20,000 個檔案、單檔 25 MiB、展開後 250 MiB、壓縮後 50 MiB。僅有來源時會推斷為 `code_review`；來源加上網域則推斷為 `live_test`。
  - 暫存的本機壓縮檔一定會被刪除。已暫存的上傳在明確拒絕後會刪除，但若因網路錯誤、`5xx`、格式錯誤的成功回應或中斷導致啟動結果不明確，則會保留。JSON 會回報其 `upload_id` 並標記 `launch_outcome_unknown: true`，若無法確認自動刪除則標記 `cleanup_unknown: true`。重試前請先檢查 `scans list`；若沒有掃描與之連結，請執行 `uploads delete UPLOAD_ID`。
  - 非企業版掃描會消耗範圍估算點數（預設等級的純來源檢視目前起價 60 點）；企業版掃描包含於方案內。被拒絕的啟動不會消耗點數。
  - 人類可讀輸出精簡且有編號；非 TTY 輸出與 `--json` 會保留完整紀錄。可用 `source <(strix completions zsh)`（或 `bash`）啟用分頁補全，或 `strix completions fish | source`。
  - 也可直接使用 REST API：https://docs.app.strix.ai（OpenAPI：https://docs.app.strix.ai/openapi.json）。

- 給 LLM 的 CLI 文件索引：https://docs.strix.ai/llms.txt（完整版：https://docs.strix.ai/llms-full.txt）。給 LLM 的受管 API 文件：https://docs.app.strix.ai/llms.txt。
- 僅掃描使用者已獲授權測試的目標。

## 貢獻本儲存庫

- Python 3.12+，以 `uv` 管理。安裝開發相依套件：`make dev-install`。
- 一次完成 lint／格式化／型別檢查／安全掃描：`make check-all`（ruff、mypy、bandit）。
- 測試：`uv run pytest`。
- 從原始碼執行：`uv run strix --target <target>`。
- 目錄結構：`strix/agents`（代理關係圖與提示詞）、`strix/tools`（代理、瀏覽器、終端機、掃描器）、`strix/runtime`（Docker 沙箱）、`strix/report`（發現、SARIF）、`strix/skills`（滲透代理載入的內部知識包 —— 與 `skills/` 中給消費者的技能不同）、`strix/interface`（CLI/TUI）、`containers/`（沙箱映像）。
- Pre-commit 掛鉤：`make pre-commit`（或 `uv run pre-commit install`）。

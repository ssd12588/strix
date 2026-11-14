# 漢化術語對照表（Glossary）

> 用途：未來任何人（或 AI）要新增／修改漢化內容時，請**照這張表翻**，避免同一個詞在不同地方譯法不一致。
>
> 原則：
> 1. **技術專有名詞保留英文**（Docker、API、SARIF、JWT、XSS…），因為使用者會在網路上搜尋原文。
> 2. **產品名不翻**（Strix、Caido、Playwright、LiteLLM）。
> 3. **指令、參數、路徑、環境變數一律不翻**。
> 4. 中文用**繁體**，標點用全角（，。（）；：）。

---

## 核心概念

| 英文 | 統一譯法 | 備註 |
|---|---|---|
| Penetration Test / Pentest | 滲透測試 | 不用「滲透測試攻擊」 |
| Penetration Tester | 滲透測試人員 | |
| Finding | 發現 | 名詞；不用「發現項目」 |
| Vulnerability | 漏洞 | |
| Exploit | 利用程式 | 動詞時用「利用」 |
| Proof of Concept (PoC) | 概念驗證（PoC） | 首次出現加註英文 |
| Severity | 嚴重度 | 不用「危險等級」 |
| Critical / High / Medium / Low / Info | 重大／高／中／低／資訊 | 值本身（`critical`）不翻 |
| Remediation | 修補建議 | |
| Fix | 修正 | 動詞「修補」也可，同段落內保持一致 |
| Verification | 驗證 | |
| False Positive | 誤報 | |
| Attack Surface | 攻擊面 | |
| Reconnaissance | 偵察 | |
| Exploitation | 利用 | |
| Post-exploitation | 後滲透 | |
| Payload | payload | **不翻**（社群慣用原文） |
| Bypass | 繞過 | |
| Chain / Chained | 串接（型） | 例：串接型漏洞 |
| Race Condition | 競態條件 | |
| Scope | 範圍 | |
| Target | 目標 | |
| Out of Scope | 不在範圍內／排除範圍 | 依語境 |

## 代理與流程

| 英文 | 統一譯法 | 備註 |
|---|---|---|
| Agent | 代理 | 不用「智能體」 |
| Sub-agent | 子代理 | |
| Root Agent | 根代理 | |
| Agent Graph | 代理關係圖 | |
| Orchestration | 協同運作 | |
| Turn | 回合 | |
| Skill | 技能 | 後方括號保留 `skills` 目錄名 |
| Prompt | 提示詞 | |
| System Prompt | 系統提示詞 | |
| Instruction | 指令 | CLI 參數 `--instruction` 不翻 |
| Guest / Sandbox | 沙箱 | |
| Workspace | 工作區 | |
| Run | 執行 | 名詞；例：本次執行 |
| Run Name | 執行名稱 | |
| Scan | 掃描 | |
| Scan Mode | 掃描模式 | |
| Quick / Standard / Deep | 快速／標準／深度 | 參數值 `quick` 等不翻 |
| Headless | 無介面 | 不用「無頭」 |
| Non-interactive | 非互動 | |
| TUI | TUI | 不翻 |
| Viewer | 檢視器 | |
| Dashboard | 儀表板 | |
| Report | 報告 | |

## 設定與環境

| 英文 | 統一譯法 | 備註 |
|---|---|---|
| Environment Variable | 環境變數 | 變數名本身不翻 |
| API Key | API 金鑰 | |
| API Base URL | API base URL | 或「API 位址」，同段落一致 |
| Provider | 供應商 | |
| Model | 模型 | |
| Token | token | 小寫、不翻（例：輸入 token） |
| Budget | 預算 | |
| Cost | 費用 | |
| Credit | 點數 | 雲端平台用 |
| Configuration | 設定 | |
| Config File | 設定檔 | |
| Default | 預設 | |
| Deprecated | 已棄用 | |
| Optional | 選用 | 不用「可選」 |
| Required | 必要 | |

## 安全分類（保留英文縮寫）

| 英文 | 處理方式 |
|---|---|
| XSS / CSRF / SSRF / XXE / RCE / SSTI | 保留縮寫，首次出現可加中文說明 |
| IDOR | 保留（不翻成「不安全的直接物件參照」） |
| SQL Injection | SQL 注入 |
| NoSQL Injection | NoSQL 注入 |
| Command Injection | 指令注入 |
| Path Traversal | 路徑穿越 |
| Insecure Deserialization | 不安全的反序列化 |
| Prototype Pollution | 原型污染 |
| Mass Assignment | 大量賦值（mass assignment） |
| Open Redirect | 開放重新導向 |
| Business Logic | 業務邏輯 |
| Broken Access Control | 存取控制失效 |
| Privilege Escalation | 權限提升 |
| Session Fixation | 工作階段固定 |
| Credential Stuffing | 憑證填充 |
| Subdomain Takeover | 子網域接管 |
| Information Disclosure | 資訊外洩 |

## 介面與檔案

| 英文 | 統一譯法 |
|---|---|
| Endpoint | 端點 |
| Header | 標頭 |
| Request / Response | 請求／回應 |
| Proxy | 代理（伺服器） |
| Intercept | 攔截 |
| Replay | 重送 |
| Sitemap | 網站地圖 |
| Cookie | Cookie（不翻） |
| Log | 日誌 |
| Traceback | 錯誤追蹤（traceback） |
| Exit Code | 結束碼 |
| Pull Request / PR | PR |
| Issue | issue（小寫，不翻） |
| Repository | 儲存庫 |
| Branch | 分支 |
| Commit | commit（不翻） |
| Fork | fork（不翻） |
| Upstream | 上游 |
| Release | 發行版 |

## 標點與排版

| 規則 | 正確 | 錯誤 |
|---|---|---|
| 破折號 | `——`（兩個全角） | `-` 或 `--` |
| 頓號 | `、` | `,` |
| 括號 | `（）` 全角（程式碼內除外） | `()` |
| 引號 | `「」` 或 `**粗體**` | `""` |
| 中英之間 | 不加空格（`使用 Docker`） | `使用Docker` |
| 數字與單位 | `5 分鐘`、`$10` | `5分鐘` |

---

## 維護方式

1. 新增譯法前，先在本表搜尋是否已有對應詞。
2. 若必須新增，請同步更新本表（一個 PR 只改一處，避免漂移）。
3. 漢化範圍與排除清單見 [README「關於本漢化版」](../README.md#關於本漢化版)。

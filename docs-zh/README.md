# 中文使用者文件

這裡是給**繁體中文使用者**的入門資料，補足 `docs/` 官方文件沒涵蓋的「在地化」問題。

## 從哪裡開始？

| 你是誰 | 先讀 |
|---|---|
| 第一次用 Strix | [10 分鐘上手](QUICKSTART.md) |
| 已經裝好但跑不起來 | [常見錯誤排錯](TROUBLESHOOTING.md) |
| 想改漢化、或貢獻翻譯 | [術語對照表](glossary.md) |
| 想看完整功能 | [官方文件（已漢化）](../docs/) |

## 本目錄內容

| 檔案 | 說明 |
|---|---|
| [`QUICKSTART.md`](QUICKSTART.md) | 從零到第一次掃描：Docker、選模型、設金鑰、看結果 |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | 把中文錯誤訊息對照回原因與解法（含 Windows 專屬問題） |
| [`glossary.md`](glossary.md) | 漢化術語對照表，確保譯法一致 |

## 一鍵啟動（Windows）

專案根目錄的 [`start-strix.ps1`](../start-strix.ps1) 會幫你：

1. 檢查 Docker 是否就緒
2. 引導你選擇模型、輸入 API Key（只需一次）
3. 記住設定，下次直接啟動

```powershell
# 第一次：互動式設定
.\start-strix.ps1

# 之後：直接指定目標
.\start-strix.ps1 -Target https://example.com

# 只驗證安裝（不耗點數、不掃描）
.\start-strix.ps1 -Check

# 想重新設定模型／金鑰
.\start-strix.ps1 -ResetConfig
```

> 📌 設定存在 `%USERPROFILE%\.strix\zh-launcher.json`（不在專案內，不會被 Git 提交）。

## 中文使用者常見的三個坑

1. **模型選錯** —— 小於 30B 的本機模型無法可靠呼叫工具，掃描會卡住。請看 [QUICKSTART 第 2 節](QUICKSTART.md#2-選一個-llm這是新手最容易卡住的一步)。
2. **頂尖模型被拒絕** —— OpenAI／Anthropic／Gemini 需要另外申請安全測試存取權，沒申請就會被模型拒絕（不是設定錯）。
3. **Windows 終端機亂碼** —— 請用 Windows Terminal + PowerShell 7，並確認字型支援中文。

## 想貢獻翻譯？

請先讀 [術語對照表](glossary.md)，並遵守：

- 技術專有名詞保留英文（Docker、JWT、SARIF…）
- 指令、參數、路徑、環境變數**一律不翻**
- 保持繁體中文與全角標點

漢化範圍與授權說明見 [主 README](../README.md#關於本漢化版)。

# 與上游同步（Upstream Sync）

> 漢化版改動了 100+ 個檔案，直接 `git merge` 一定會衝突。
> 這個流程的目標是：**先看清楚會撞哪裡，再決定怎麼合**。

---

## 檔案與指令

| 指令 | 作用 |
|---|---|
| `.\scripts\sync-upstream.ps1` | 只分析（落後多少、哪些檔案會衝突），**不改任何檔案** |
| `.\scripts\sync-upstream.ps1 -Unshallow` | 首次用：補齊完整 Git 歷史（否則無法精準算衝突） |
| `.\scripts\sync-upstream.ps1 -Merge` | 真的合併（會產生衝突，需手工處理） |

---

## 標準流程

### 第 0 次（只做一次）

```powershell
cd C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh
.\scripts\sync-upstream.ps1 -Unshallow
```

補齊歷史後，之後都不需要再加這個參數。

### 每次要同步時

```powershell
# ① 先備份（保險，出事可回到這裡）
git branch backup-zh-$(Get-Date -Format 'yyyyMMdd')

# ② 分析：會落後多少、哪些檔案會衝突
.\scripts\sync-upstream.ps1

# ③ 看它產出的報告
#    engagements\sync-report-<時間>.md
```

### 決定要不要合併

| 報告顯示 | 建議 |
|---|---|
| `落後 0 個 commit` | 不需要做任何事 |
| 落後少、衝突檔案 < 5 個 | 可以合：`.\scripts\sync-upstream.ps1 -Merge` |
| 落後多、衝突檔案 > 20 個 | 考慮只挑重要功能（cherry-pick），或等有完整時間再處理 |
| 只有安全性修補 | 優先合，即使衝突多 |

### 合併（進階）

```powershell
.\scripts\sync-upstream.ps1 -Merge
```

出現衝突時：

```powershell
# 看哪些檔案衝突
git diff --name-only --diff-filter=U

# 開檔找 <<<<<<< ======= >>>>>>> 三段，保留「我方漢化 + 上游新功能」
# 解決後：
git add <檔案>
git commit

# 情況不對就放棄：
git merge --abort
```

### 合併後驗證（必做）

```powershell
uv run strix --help                      # 中文
cd strix/interface/tui; go test ./...    # TUI
cd ../..; uv run pytest -q               # Python
uv run strix view                        # 前端（若上游改了前端，要重新 npm run build）
```

驗證通過才推送：

```powershell
git push origin main
git checkout zh-TW; git merge --ff-only main; git push origin zh-TW; git checkout main
```

---

## 衝突常見類型與處理

| 衝突檔案 | 通常原因 | 處理方式 |
|---|---|---|
| `strix/interface/cli_args.py` | 上游新增參數 → 我們的 `help=` 中文被改 | 保留上游新參數，把它的 help 翻成中文 |
| `strix/interface/tui/**/*.go` | 上游改 TUI 邏輯 | 保留上游邏輯，重新套用中文文案 |
| `docs/**/*.mdx` | 上游更新文件 | 取上游新版，重新漢化該段落 |
| `README.md` | 上游改介紹 | 保留我們的「關於本漢化版」，其餘取上游 |
| `strix/interface/viewer/frontend/src/**` | 上游改前端 | 保留結構，重新套用中文；改完必須 `npm run build` |
| `system_prompt.jinja` | 我們加了 LANGUAGE 規則 | 保留該段，其餘取上游 |

---

## 合併後別忘了

1. **上游新增的英文字串要補翻譯**（新參數、新錯誤訊息、新面板）
2. **前端重建**：`cd strix/interface/viewer/frontend; npm run build`
3. **更新 `docs-zh/PROJECT-STATUS.md`** 的版本基準
4. **更新版本號與 Release**（例如 `v1.8.0-zh.1`）

---

## 常見問題

| 問題 | 解法 |
|---|---|
| `fatal: refusing to merge unrelated histories` | `git merge upstream/main --allow-unrelated-histories` |
| `merge-base` 算不出來 | 先跑 `-Unshallow` |
| 合併後 TUI 編譯失敗 | 上游改了 Go 相依：`cd strix/interface/tui; go mod tidy; go build ./...` |
| 合併後測試大量失敗 | 多半是「測試斷言的英文原文」被上游改了 → 對照新版更新斷言 |
| 想放棄整次合併 | `git merge --abort`，再 `git reset --hard backup-zh-<日期>` |

# Strix 漢化版 · 上游同步助手
# 用途：抓取上游更新 → 分析衝突風險 → 給你處理建議（預設不自動合併）
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File .\scripts\sync-upstream.ps1
#   pwsh -File .\scripts\sync-upstream.ps1              # 只看報告
#   pwsh -File .\scripts\sync-upstream.ps1 -Unshallow   # 補齊完整歷史（首次建議執行）
#   pwsh -File .\scripts\sync-upstream.ps1 -Merge       # 真的合併並列出衝突

param(
    [switch]$Unshallow,
    [switch]$Merge,
    [string]$UpstreamUrl = 'https://github.com/usestrix/strix.git'
)

$ErrorActionPreference = 'Stop'

try { chcp 65001 | Out-Null } catch { }
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

function Step($m) { Write-Host "`n== $m ==" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }
function Info($m) { Write-Host "  $m" -ForegroundColor Gray }

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path (Join-Path $root '.git'))) {
    Bad "這不是 Git 倉庫：$root"
    exit 1
}

# ---------- 1. 確認 upstream ----------
Step '檢查 upstream remote'
$remotes = git remote
if ($remotes -notcontains 'upstream') {
    Warn '尚未設定 upstream，正在加入…'
    git remote add upstream $UpstreamUrl
    Ok "已加入 upstream → $UpstreamUrl"
} else {
    $url = git remote get-url upstream
    Ok "upstream = $url"
}

$branch = git rev-parse --abbrev-ref HEAD
Ok "目前分支：$branch"

# ---------- 2. 檢查是否為淺層 clone ----------
Step '檢查 Git 歷史完整性'
$shallow = Test-Path (Join-Path $root '.git\shallow')
if ($shallow) {
    Warn '這是淺層 clone（shallow），無法計算 merge-base，衝突分析會不準'
    if ($Unshallow) {
        Info '正在補齊完整歷史（可能需要幾分鐘）…'
        git fetch --unshallow upstream
        if ($LASTEXITCODE -eq 0) { Ok '已補齊完整歷史' } else { Bad '補齊失敗，請手動執行：git fetch --unshallow upstream' }
    } else {
        Info '建議先執行：.\scripts\sync-upstream.ps1 -Unshallow'
    }
} else {
    Ok '歷史完整'
}

# ---------- 3. 抓取上游 ----------
Step '抓取上游更新'
git fetch upstream --tags --prune
if ($LASTEXITCODE -ne 0) { Bad 'fetch 失敗，請檢查網路或 upstream 網址'; exit 1 }
Ok 'fetch 完成'

$upstreamRef = 'upstream/main'
$exists = git rev-parse --verify --quiet $upstreamRef
if (-not $exists) { Bad "找不到 $upstreamRef"; exit 1 }

# ---------- 4. 統計落差 ----------
Step '落差統計'
$behind = git rev-list --count "HEAD..$upstreamRef"
$ahead  = git rev-list --count "$upstreamRef..HEAD"
$base   = ($behind -eq 0)

Write-Host "  上游比我們多：$behind 個 commit" -ForegroundColor White
Write-Host "  我們比上游多：$ahead 個 commit（漢化）" -ForegroundColor White

if ($behind -eq '0') {
    Ok '已經是最新，不需要同步'
    Write-Host ''
    exit 0
}

Write-Host ''
Info '最近的 10 個上游更新：'
git log --oneline --no-decorate -10 "HEAD..$upstreamRef" | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

# ---------- 5. 衝突風險分析 ----------
Step '衝突風險分析'

$mergeBase = $null
try {
    $mergeBase = (git merge-base HEAD $upstreamRef 2>$null)
    if ([string]::IsNullOrWhiteSpace($mergeBase)) { $mergeBase = $null }
} catch { $mergeBase = $null }

if (-not $mergeBase) {
    Warn '無法計算 merge-base（淺層 clone），改用「檔案清單比對」粗略分析'
    $upstreamFiles = git diff --name-only "HEAD..$upstreamRef"
    $oursFiles     = @()
} else {
    Ok "merge-base = $($mergeBase.Substring(0, 8))"
    $upstreamFiles = git diff --name-only "$mergeBase..$upstreamRef"
    $oursFiles     = git diff --name-only "$mergeBase..HEAD"
}

$upstreamFiles = @($upstreamFiles | Where-Object { $_ })
$oursFiles     = @($oursFiles     | Where-Object { $_ })

$risk = @($upstreamFiles | Where-Object { $oursFiles -contains $_ })
$safe = @($upstreamFiles | Where-Object { $oursFiles -notcontains $_ })

Write-Host "  上游改了：$($upstreamFiles.Count) 個檔案" -ForegroundColor White
Write-Host "  我們漢化過：$($oursFiles.Count) 個檔案" -ForegroundColor White
Write-Host "  同時被改（會衝突）：$($risk.Count) 個" -ForegroundColor Yellow

if ($risk.Count -gt 0) {
    Write-Host ''
    Warn '以下檔案「上游改過、我們也漢化過」，合併時需要手工處理：'
    $risk | Select-Object -First 40 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    if ($risk.Count -gt 40) { Info "…另有 $($risk.Count - 40) 個" }
}

if ($safe.Count -gt 0) {
    Write-Host ''
    Ok "以下 $($safe.Count) 個檔案只有上游改動，可直接接受（不影響漢化）"
}

# ---------- 6. 產出報告 ----------
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$reportDir = Join-Path $root 'engagements'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
$reportPath = Join-Path $reportDir "sync-report-$stamp.md"

$lines = @(
    "# 上游同步報告 $stamp",
    '',
    "- 目前分支：$branch",
    "- 落後：$behind 個 commit",
    "- 領先（漢化）：$ahead 個 commit",
    "- merge-base：$mergeBase",
    '',
    '## 會衝突的檔案（上游改過且我們漢化過）',
    '',
    $($risk | ForEach-Object { "- $_" }),
    '',
    '## 只有上游改動（可直接接受）',
    '',
    $($safe | ForEach-Object { "- $_" }),
    '',
    '## 上游最近更新',
    '',
    $((git log --oneline --no-decorate -20 "HEAD..$upstreamRef") | ForEach-Object { "- $_" })
)
$lines -join "`r`n" | Set-Content -Path $reportPath -Encoding UTF8
Ok "報告已存：$reportPath"

# ---------- 7. 建議 ----------
Step '建議處理方式'

Write-Host '  ① 先備份目前狀態（保險）' -ForegroundColor White
Info "git branch backup-zh-$stamp"
Write-Host '  ② 合併上游（會產生衝突，需逐一解決）' -ForegroundColor White
Info '.\scripts\sync-upstream.ps1 -Merge'
Write-Host '  ③ 合併後重新漢化「新增的英文字串」' -ForegroundColor White
Info '檢查衝突檔案裡上游新增的英文，補上中文'
Write-Host '  ④ 驗證後推送' -ForegroundColor White
Info 'uv run strix --help；cd strix/interface/tui; go test ./...'
Info 'git push origin main'

# ---------- 8. 真的合併（需明確指定 -Merge） ----------
if ($Merge) {
    Step '開始合併'
    Warn '合併可能產生衝突。若情況不妙，可用：git merge --abort 取消'
    $go = Read-Host '  確定要合併 upstream/main 嗎？(y/N)'
    if ($go -notin @('y', 'Y')) { Info '已取消'; exit 0 }

    git merge $upstreamRef --no-edit
    $mergeCode = $LASTEXITCODE

    if ($mergeCode -eq 0) {
        Ok '合併成功，沒有衝突'
        Info '請執行驗證：uv run strix --help；go test ./...'
    } else {
        Warn '合併有衝突，以下檔案需要手工處理：'
        git diff --name-only --diff-filter=U | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
        Write-Host ''
        Info '處理方式：'
        Info '  1. 開檔解決 <<<<<<< / ======= / >>>>>>> 區塊'
        Info '  2. git add <檔案>'
        Info '  3. git commit'
        Info '  或放棄：git merge --abort'
    }
} else {
    Write-Host ''
    Info '（本次只做分析，未變更任何檔案。要真的合併請加 -Merge）'
}

Write-Host ''


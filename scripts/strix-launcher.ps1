# Strix 漢化版 · 桌面啟動器
# 由桌面捷徑 (.bat) 呼叫；也可直接執行：
#   powershell -ExecutionPolicy Bypass -File .\scripts\strix-launcher.ps1
param(
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

# ---------- 0. 終端編碼 ----------
try { chcp 65001 | Out-Null } catch { }
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

function Line { Write-Host ('-' * 62) -ForegroundColor DarkGray }
function Title($t) {
    Clear-Host
    Write-Host ''
    Write-Host '  Strix 漢化版 · 啟動器' -ForegroundColor Cyan
    Line
    Write-Host "  $t" -ForegroundColor White
    Write-Host ''
}
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }

# ---------- 1. 專案路徑 ----------
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root 'pyproject.toml'))) {
    Bad "找不到專案根目錄（預期含 pyproject.toml）：$root"
    if (-not $NoPause) { Read-Host '按 Enter 結束' }
    exit 1
}
Set-Location $root

# ---------- 2. 環境檢查 ----------
Title '檢查環境'

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Bad '找不到 uv（套件管理工具）'
    Write-Host '     請先安裝：powershell -c "irm https://astral.sh/uv/install.ps1 | iex"' -ForegroundColor Gray
    if (-not $NoPause) { Read-Host '按 Enter 結束' }
    exit 1
}
Ok 'uv 已安裝'

$dockerOk = $false
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) { $dockerOk = $true; Ok 'Docker 正在執行' }
    else { Warn 'Docker 已安裝但未執行 — 請先開啟 Docker Desktop' }
} else {
    Bad '找不到 Docker — 請安裝 Docker Desktop'
}
if (-not $dockerOk) {
    Write-Host ''
    Write-Host '  仍要繼續嗎？（掃描時會失敗）' -ForegroundColor Yellow
    $go = Read-Host '  繼續？(y/N)'
    if ($go -notin @('y', 'Y')) { exit 1 }
}

# ---------- 3. 選擇指令檔 ----------
Title '選擇任務類型（.md 指令檔）'

$instrDir = Join-Path $root 'instructions'
$files = @()
if (Test-Path $instrDir) {
    $files = Get-ChildItem $instrDir -Filter *.md | Sort-Object Name
}

Write-Host '  [0] 不指定（自由對話，讓 AI 自己決定）' -ForegroundColor Gray
for ($i = 0; $i -lt $files.Count; $i++) {
    $n = $files[$i].Name
    Write-Host ("  [{0}] {1}" -f ($i + 1), $n) -ForegroundColor Gray
}
Write-Host ''
$pick = Read-Host '  輸入編號（預設 0）'
if ([string]::IsNullOrWhiteSpace($pick)) { $pick = '0' }

$instructionFile = $null
if ($pick -ne '0') {
    $idx = [int]$pick - 1
    if ($idx -ge 0 -and $idx -lt $files.Count) {
        $instructionFile = $files[$idx].FullName
        Ok "已選：$($files[$idx].Name)"
    } else {
        Warn '編號無效，改為不指定'
    }
} else {
    Ok '不指定指令檔'
}

# ---------- 4. 輸入目標 ----------
Title '輸入要測試的站點'

Write-Host '  格式範例：' -ForegroundColor DarkGray
Write-Host '    網域（會做子網域收集）：  tw17.com.tw' -ForegroundColor DarkGray
Write-Host '    完整網址（只測主站）：    https://tw17.com.tw' -ForegroundColor DarkGray
Write-Host '    本機專案：               ./你的專案' -ForegroundColor DarkGray
Write-Host ''

$target = $null
while ([string]::IsNullOrWhiteSpace($target)) {
    $target = Read-Host '  目標'
    if ([string]::IsNullOrWhiteSpace($target)) { Warn '不能為空，請重新輸入' }
}
$target = $target.Trim()

# 判斷是否為純網域
$isBareDomain = ($target -notmatch '^https?://') -and ($target -notmatch '[/\\]')
if ($isBareDomain) {
    Ok "純網域 → 會進行子網域收集"
} else {
    Warn '網址或路徑 → 只會測試該目標本身'
}

# ---------- 5. 掃描模式 ----------
Title '掃描模式'

Write-Host '  [1] quick    最快、最省（建議先跑，5-10 分鐘）' -ForegroundColor Gray
Write-Host '  [2] standard 中等（約 30 分鐘）' -ForegroundColor Gray
Write-Host '  [3] deep     徹底（1-4 小時）' -ForegroundColor Gray
Write-Host ''
$m = Read-Host '  輸入編號（預設 1）'
if ([string]::IsNullOrWhiteSpace($m)) { $m = '1' }
if ($m -eq '2') { $scanMode = 'standard' }
elseif ($m -eq '3') { $scanMode = 'deep' }
else { $scanMode = 'quick' }
Ok "模式：$scanMode"

# ---------- 6. 預算 ----------
Title '花費上限（美元）'

Write-Host '  建議：資產收集 1、PII 稽核 2-5' -ForegroundColor DarkGray
$b = Read-Host '  上限（預設 1）'
if ([string]::IsNullOrWhiteSpace($b)) { $b = '1' }
Ok "上限：`$$b"

# ---------- 7. 確認 ----------
Title '確認後開始'
Write-Host "  目標：    $target" -ForegroundColor White
Write-Host "  指令檔：  $(if ($instructionFile) { Split-Path -Leaf $instructionFile } else { '（不指定）' })" -ForegroundColor White
Write-Host "  模式：    $scanMode" -ForegroundColor White
Write-Host "  預算：    `$$b" -ForegroundColor White
Write-Host ''
$go = Read-Host '  開始掃描？(Y/n)'
if ($go -in @('n', 'N')) { Write-Host '  已取消'; if (-not $NoPause) { Read-Host '按 Enter 結束' }; exit 0 }

# ---------- 8. 執行 ----------
Title '啟動 Strix'
Write-Host '  首次執行會下載沙箱映像（數 GB），請耐心等待…' -ForegroundColor DarkGray
Write-Host '  操作鍵：esc 停止｜ctrl+q 離開｜輸入框可給代理指示' -ForegroundColor DarkGray
Write-Host ''

$cliArgs = @('run', 'strix', '--target', $target, '--scan-mode', $scanMode, '--max-budget', $b)
if ($instructionFile) { $cliArgs += @('--instruction-file', $instructionFile) }

& uv @cliArgs
$code = $LASTEXITCODE

# ---------- 9. 結束處理 ----------
Line
switch ($code) {
    0 { Ok '掃描完成（未達 --fail-on 門檻，或沒有發現）' }
    1 { Bad '執行錯誤 — 請看上方訊息，或查 docs-zh\TROUBLESHOOTING.md' }
    2 { Warn '發現漏洞（結束碼 2）' }
    default { Write-Host "  結束碼：$code" -ForegroundColor Gray }
}

if ($code -eq 0 -or $code -eq 2) {
    Write-Host ''
    $v = Read-Host '  要開啟 Web 儀表板看結果嗎？(Y/n)'
    if ($v -notin @('n', 'N')) {
        Write-Host '  啟動 strix view（按 Ctrl+C 關閉）…' -ForegroundColor DarkGray
        & uv run strix view
    }
}

Write-Host ''
if (-not $NoPause) { Read-Host '按 Enter 結束' }


<#
.SYNOPSIS
  Strix 漢化版 · Windows 一鍵啟動

.DESCRIPTION
  幫你完成：檢查 Docker → 確認模型與金鑰 → 啟動 Strix。
  設定會記住（存在 %USERPROFILE%\.strix\zh-launcher.json），下次不必重輸。

.PARAMETER Target
  要掃描的目標（網址、網域、IP 或本機目錄）。省略時會詢問。

.EXAMPLE
  .\start-strix.ps1 -Target https://example.com

.EXAMPLE
  # 只跑不耗點數的檢查
  .\start-strix.ps1 -Check

.NOTES
  建議使用 PowerShell 7（pwsh），中文顯示較穩定。
  若無法執行腳本，先執行：
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#>

[CmdletBinding()]
param(
    [string]$Target,
    [switch]$Check,
    [switch]$ResetConfig,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$StrixArgs
)

$ErrorActionPreference = 'Stop'

# ---------- 0. 終端編碼（中文顯示） ----------
try { chcp 65001 | Out-Null } catch { }
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

function Write-Step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [X]  $msg" -ForegroundColor Red }

# ---------- 1. 檢查 Docker ----------
Write-Step '檢查 Docker'
$dockerOk = $false
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        $dockerOk = $true
        Write-Ok 'Docker 正在執行'
    } else {
        Write-Err 'Docker 已安裝，但沒有在執行'
        Write-Host '       請開啟 Docker Desktop，等狀態變成 Engine running 再試。' -ForegroundColor Gray
    }
} else {
    Write-Err '找不到 docker 指令'
    Write-Host '       請安裝 Docker Desktop：https://www.docker.com/products/docker-desktop/' -ForegroundColor Gray
    Write-Host '       安裝後請「完全關閉終端機再重開」，PATH 才會生效。' -ForegroundColor Gray
}

# ---------- 2. 確認 strix 可用 ----------
Write-Step '確認 Strix'
$repoRoot = Split-Path -Parent $PSCommandPath
$strixCmd = $null
$useUv = $false

if (Get-Command strix -ErrorAction SilentlyContinue) {
    $strixCmd = 'strix'
    Write-Ok "使用已安裝的 strix（$((Get-Command strix).Source)）"
} elseif ((Test-Path (Join-Path $repoRoot 'pyproject.toml')) -and (Get-Command uv -ErrorAction SilentlyContinue)) {
    $strixCmd = 'uv'
    $useUv = $true
    Write-Ok '使用原始碼模式（uv run strix）'
} else {
    Write-Err '找不到 strix，也找不到可用的 uv + 原始碼'
    Write-Host '       請在本專案目錄執行，或先安裝：uv tool install .' -ForegroundColor Gray
    exit 1
}

# ---------- 3. 模型與金鑰 ----------
Write-Step '確認 LLM 設定'

$configDir  = Join-Path $env:USERPROFILE '.strix'
$configPath = Join-Path $configDir 'zh-launcher.json'

if ($ResetConfig -and (Test-Path $configPath)) {
    Remove-Item $configPath -Force
    Write-Warn2 '已清除先前的啟動設定'
}

$saved = $null
if (Test-Path $configPath) {
    try { $saved = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
}

$model   = $env:STRIX_LLM
if (-not $model   -and $saved) { $model   = $saved.STRIX_LLM }
$apiKey  = $env:LLM_API_KEY
if (-not $apiKey  -and $saved) { $apiKey  = $saved.LLM_API_KEY }
$apiBase = $env:LLM_API_BASE
if (-not $apiBase -and $saved) { $apiBase = $saved.LLM_API_BASE }

if (-not $model) {
    Write-Host '  請選擇要使用的模型：' -ForegroundColor White
    $models = @(
        @{ Name = 'DeepSeek V4 Pro（便宜、中文好）';    Id = 'deepseek/deepseek-v4-pro' },
        @{ Name = 'GLM-5.3 via OpenRouter（官方推薦）';  Id = 'openrouter/z-ai/glm-5.3' },
        @{ Name = 'GLM-5.3 via Vercel AI Gateway';       Id = 'vercel_ai_gateway/zai/glm-5.3' },
        @{ Name = 'Kimi K3.1 Pro';                       Id = 'moonshot/kimi-k3.1-pro' },
        @{ Name = 'OpenAI GPT-6.1 Sol（需 Daybreak）';   Id = 'openai/gpt-6.1-sol' },
        @{ Name = '本機 Ollama qwen3-vl（需 GPU）';      Id = 'ollama/qwen3-vl' },
        @{ Name = '自行輸入';                             Id = '__custom__' }
    )
    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host ("    [{0}] {1}  ({2})" -f ($i + 1), $models[$i].Name, $models[$i].Id) -ForegroundColor Gray
    }
    $pick = Read-Host '  輸入編號（預設 1）'
    if ([string]::IsNullOrWhiteSpace($pick)) { $pick = '1' }
    $idx = [int]$pick - 1
    if ($idx -lt 0 -or $idx -ge $models.Count) { $idx = 0 }
    $model = $models[$idx].Id
    if ($model -eq '__custom__') {
        $model = Read-Host '  請輸入完整模型名稱（例如 openrouter/z-ai/glm-5.3）'
    }
}

if (-not $apiKey) {
    if ($model -like 'ollama/*') {
        Write-Ok 'Ollama 本機模型不需要 API Key'
        if (-not $apiBase) { $apiBase = 'http://localhost:11434' }
    } else {
        $secure = Read-Host '  請貼上 API Key（輸入時不會顯示）' -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    }
}

if ($model -notlike '*/*') {
    Write-Warn2 "模型名稱缺少供應商前綴，可能被當成 OpenAI 模型：$model"
}

try {
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $out = [ordered]@{ STRIX_LLM = $model }
    if ($apiKey)  { $out['LLM_API_KEY']  = $apiKey }
    if ($apiBase) { $out['LLM_API_BASE'] = $apiBase }
    ($out | ConvertTo-Json) | Set-Content -Path $configPath -Encoding UTF8
    Write-Ok "已記住設定：$configPath"
} catch {
    Write-Warn2 "無法儲存設定（不影響本次執行）：$($_.Exception.Message)"
}

$env:STRIX_LLM = $model
if ($apiKey)  { $env:LLM_API_KEY  = $apiKey }
if ($apiBase) { $env:LLM_API_BASE = $apiBase }
Write-Host "  模型：$model" -ForegroundColor Gray

# ---------- 4. 只有檢查模式 ----------
if ($Check) {
    Write-Step '執行安裝驗證（不耗點數）'
    if ($useUv) { & $strixCmd run strix --help } else { & $strixCmd --help }
    if (-not $dockerOk) { exit 1 }
    Write-Ok '檢查完成，環境看起來正常'
    exit 0
}

if (-not $dockerOk) {
    Write-Err 'Docker 沒有就緒，無法掃描'
    exit 1
}

# ---------- 5. 目標 ----------
$hasTargetArg = ($StrixArgs -contains '--target') -or ($StrixArgs -contains '-t')
if (-not $Target -and -not $hasTargetArg) {
    $Target = Read-Host '  請輸入要掃描的目標（網址／網域／IP／本機目錄）'
}
if ([string]::IsNullOrWhiteSpace($Target) -and -not $hasTargetArg) {
    Write-Err '沒有目標，結束'
    exit 1
}

# ---------- 6. 啟動 ----------
Write-Step '啟動 Strix'
Write-Host '  首次執行會下載沙箱映像（數 GB），請耐心等待…' -ForegroundColor Gray
Write-Host '  按 Ctrl+C 可中止；結果會存在 strix_runs\ 底下' -ForegroundColor Gray
Write-Host ''

$allArgs = @()
if ($Target)   { $allArgs += @('--target', $Target) }
if ($StrixArgs){ $allArgs += $StrixArgs }

if ($useUv) { & $strixCmd run strix @allArgs } else { & $strixCmd @allArgs }
$code = $LASTEXITCODE

Write-Host ''
switch ($code) {
    0  { Write-Ok '掃描完成（沒有發現漏洞，或未達到 --fail-on 門檻）' }
    1  { Write-Err '發生錯誤（請見上方訊息，或查 docs-zh\TROUBLESHOOTING.md）' }
    2  { Write-Warn2 '發現漏洞（結束碼 2）— 用 strix view 查看詳情' }
    default { Write-Host "  結束碼：$code" -ForegroundColor Gray }
}
Write-Host '  檢視結果：' -ForegroundColor Gray
if ($useUv) { Write-Host '    uv run strix view' -ForegroundColor White }
else        { Write-Host '    strix view' -ForegroundColor White }
exit $code

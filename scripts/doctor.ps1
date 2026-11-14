# Strix 漢化版 · 環境體檢
# 一次檢查所有前置條件，用中文告訴你缺什麼、怎麼補
#
# 用法：
#   .\scripts\doctor.ps1
#   .\scripts\doctor.ps1 -FixImage   # 順便幫你拉沙箱映像

param(
    [switch]$FixImage
)

$ErrorActionPreference = 'Continue'
try { chcp 65001 | Out-Null } catch { }
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root = Split-Path -Parent $PSScriptRoot
$issues = 0
$warnings = 0

function Section($t) {
    Write-Host ''
    Write-Host "== $t ==" -ForegroundColor Cyan
}
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow; $script:warnings++ }
function Bad($m)  { Write-Host "  [X]  $m" -ForegroundColor Red; $script:issues++ }
function Hint($m) { Write-Host "       → $m" -ForegroundColor DarkGray }

Write-Host ''
Write-Host '  Strix 漢化版 · 環境體檢' -ForegroundColor White
Write-Host ('-' * 60) -ForegroundColor DarkGray

# ---------- 1. 作業系統與 Shell ----------
Section '系統環境'
Ok "Windows $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor)"
$psv = $PSVersionTable.PSVersion
if ($psv.Major -ge 7) { Ok "PowerShell $psv（建議版本）" }
else { Warn "PowerShell $psv（建議安裝 PowerShell 7，中文顯示較穩定）"; Hint 'winget install Microsoft.PowerShell' }

$arch = $env:PROCESSOR_ARCHITECTURE
Ok "架構：$arch"

# ---------- 2. Git ----------
Section 'Git'
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gv = (git --version) -replace 'git version ', ''
    Ok "git $gv"
} else {
    Bad '找不到 git'
    Hint 'winget install Git.Git'
}

# ---------- 3. uv ----------
Section 'uv（Python 套件管理）'
$uv = Get-Command uv -ErrorAction SilentlyContinue
if ($uv) {
    Ok "uv $((uv --version) -replace 'uv ', '')"
} else {
    Bad '找不到 uv'
    Hint 'powershell -c "irm https://astral.sh/uv/install.ps1 | iex"'
}

# ---------- 4. Docker ----------
Section 'Docker'
$dockerCli = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCli) {
    Bad '找不到 docker 指令'
    Hint '安裝 Docker Desktop：https://www.docker.com/products/docker-desktop/'
    Hint '安裝後請完全關閉終端機再重開'
} else {
    Ok "docker CLI 已安裝"
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        $sv = docker version --format '{{.Server.Version}}' 2>$null
        Ok "Docker daemon 正在執行（$sv）"
    } else {
        Bad 'Docker daemon 沒有執行'
        Hint '開啟 Docker Desktop，等狀態變成 Engine running'
    }
}

# ---------- 5. 沙箱映像 ----------
Section '沙箱映像'
$imageName = 'ghcr.io/usestrix/strix-sandbox:1.4.1'
$hasImage = $false
if ($dockerCli) {
    $img = docker images --format '{{.Repository}}:{{.Tag}}' 2>$null | Where-Object { $_ -like 'ghcr.io/usestrix/strix-sandbox*' }
    if ($img) {
        $hasImage = $true
        Ok "已下載：$($img -join ', ')"
    } else {
        Warn '沙箱映像尚未下載（首次掃描會自動拉取，約 3–5 GB）'
        Hint "手動拉取：docker pull $imageName"
        if ($FixImage) {
            Write-Host '       正在拉取，請稍候…' -ForegroundColor DarkGray
            docker pull $imageName
            if ($LASTEXITCODE -eq 0) { Ok '映像拉取完成' } else { Bad '映像拉取失敗（可能是網路問題）' }
        }
    }
}

# ---------- 6. 磁碟空間 ----------
Section '磁碟空間'
$drive = (Get-Item $root).PSDrive
$free = [math]::Round((Get-PSDrive $drive.Name).Free / 1GB, 1)
if ($free -ge 10) { Ok "可用空間 $free GB" }
elseif ($free -ge 5) { Warn "可用空間 $free GB（建議至少 10 GB）" }
else { Bad "可用空間僅 $free GB（沙箱映像需要 3–5 GB）"; Hint '清理磁碟：docker system prune -a' }

# ---------- 7. 網路連通性 ----------
Section '網路連通性（443 埠）'
foreach ($targetHost in @('ghcr.io', 'api.deepseek.com')) {
    try {
        $r = Test-NetConnection -ComputerName $targetHost -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    } catch { $r = $false }
    if ($r) { Ok "$targetHost 可連線" }
    else {
        Warn "$targetHost 無法連線"
        if ($targetHost -eq 'ghcr.io') { Hint '中國大陸常見：設定 Docker registry mirror（見 docs-zh/TROUBLESHOOTING.md）' }
        else { Hint "該供應商不可用，請改選其他模型（見 docs-zh/QUICKSTART.md 第 2 節）" }
    }
}

# ---------- 8. 模型與金鑰 ----------
Section 'LLM 設定'
$cfgPath = Join-Path $env:USERPROFILE '.strix\zh-launcher.json'
$model = $env:STRIX_LLM
$key = $env:LLM_API_KEY
if (-not $model -and (Test-Path $cfgPath)) {
    try { $c = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json; $model = $c.STRIX_LLM; if (-not $key) { $key = $c.LLM_API_KEY } } catch { }
}
if ($model) { Ok "模型：$model" } else { Bad '未設定 STRIX_LLM'; Hint '執行桌面啟動器選 [1]，或 docs-zh/QUICKSTART.md 第 5 節' }
if ($key) { Ok 'API 金鑰已設定' }
elseif ($model -like 'ollama/*') { Ok '本機 Ollama 模型不需要金鑰' }
elseif ($model) { Warn '未設定 LLM_API_KEY'; Hint '啟動器會引導你輸入' }
else { Warn '未設定 LLM_API_KEY' }

# ---------- 9. 專案完整性 ----------
Section '專案檔案'
foreach ($rel in @('pyproject.toml', 'scripts\strix-launcher.ps1', 'instructions\recon-only.md', 'docs-zh\QUICKSTART.md')) {
    if (Test-Path (Join-Path $root $rel)) { Ok $rel } else { Warn "缺少 $rel" }
}
$venv = Join-Path $root '.venv'
if (Test-Path $venv) { Ok '.venv 已建立' } else { Warn '.venv 未建立'; Hint 'uv sync' }

# ---------- 總結 ----------
Write-Host ''
Write-Host ('-' * 60) -ForegroundColor DarkGray
if ($issues -eq 0 -and $warnings -eq 0) {
    Write-Host '  全部通過，可以開始使用 🎉' -ForegroundColor Green
    Write-Host '  下一步：雙擊桌面「Strix漢化版」→ 選 [1] → 輸入目標' -ForegroundColor Gray
} elseif ($issues -eq 0) {
    Write-Host "  可用，但有 $warnings 項建議處理" -ForegroundColor Yellow
} else {
    Write-Host "  有 $issues 項必須處理、$warnings 項建議處理" -ForegroundColor Red
    Write-Host '  排錯說明：docs-zh/TROUBLESHOOTING.md' -ForegroundColor Gray
}
Write-Host ''

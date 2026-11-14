# 本機版資產收集（不需 LLM，費用 $0）
# 用 Docker 跑 ProjectDiscovery 工具鏈，輸出直接留在本機
#
# 用法：
#   .\scripts\recon-local.ps1 -Domain kmsh.org.tw -Client kmsh
#   .\scripts\recon-local.ps1 -Domain example.com -Client demo -OutDir C:\recon\demo

param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [string]$Client = '',
    [string]$OutDir = '',
    [switch]$SkipPorts
)

$ErrorActionPreference = 'Stop'
try { chcp 65001 | Out-Null } catch { }
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Step($m) { Write-Host "`n== $m ==" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }

if ([string]::IsNullOrWhiteSpace($Client)) { $Client = ($Domain -replace '[^a-zA-Z0-9]', '-') }
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = Join-Path $env:TEMP "strix-recon\$Client" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$winOut = $OutDir
$script:errors = 0

Write-Host ''
Write-Host '  Strix 漢化版 · 本機資產收集' -ForegroundColor Cyan
Write-Host ('-' * 60) -ForegroundColor DarkGray
Write-Host "  目標網域：$Domain"
Write-Host "  輸出目錄：$winOut"

# ---------- Docker 檢查 ----------
Step '檢查 Docker'
$null = docker info 2>$null
if ($LASTEXITCODE -ne 0) { Bad 'Docker 未執行，請先開啟 Docker Desktop'; exit 1 }
Ok 'Docker 就緒'

# 掛載路徑（避免中文路徑問題，使用純英文的 TEMP 目錄）
$mount = "/out"

function Run-Tool($image, $args, $labelFile) {
    Write-Host "  → $image" -ForegroundColor DarkGray
    & docker run --rm -v "${winOut}:/out" $image @args
    if ($LASTEXITCODE -ne 0) {
        Warn "$($image) 結束碼 $LASTEXITCODE（$labelFile）"
        $script:errors++
    }
}

# ---------- 1. 子網域 ----------
Step '子網域列舉（subfinder）'
Run-Tool 'projectdiscovery/subfinder:latest' @('-d', $Domain, '-all', '-silent', '-o', "$mount/subdomains.txt") 'subdomains.txt'
$subFile = Join-Path $winOut 'subdomains.txt'
if (Test-Path $subFile) {
    $n = (Get-Content $subFile -ErrorAction SilentlyContinue | Where-Object { $_ }).Count
    Ok "子網域：$n 筆"
}

# ---------- 2. DNS 解析 ----------
Step 'DNS 解析（dnsx）'
if (Test-Path $subFile) {
    Run-Tool 'projectdiscovery/dnsx:latest' @('-l', "$mount/subdomains.txt", '-a', '-cname', '-resp', '-silent', '-o', "$mount/dns.txt") 'dns.txt'
}

# ---------- 3. HTTP 探測 ----------
Step 'HTTP 探測（httpx，僅保留 200/301/302/400/401/403/405）'
if (Test-Path $subFile) {
    Run-Tool 'projectdiscovery/httpx:latest' @(
        '-l', "$mount/subdomains.txt",
        '-sc', '-title', '-td', '-silent', '-rate-limit', '5',
        '-mc', '200,301,302,400,401,403,405',
        '-o', "$mount/httpx.txt"
    ) 'httpx.txt'
}

# ---------- 4. 埠掃描（可選） ----------
if (-not $SkipPorts) {
    Step '埠掃描（naabu，top 100）'
    if (Test-Path $subFile) {
        Run-Tool 'projectdiscovery/naabu:latest' @('-list', "$mount/subdomains.txt", '-top-ports', '100', '-silent', '-rate', '300', '-o', "$mount/ports.txt") 'ports.txt'
    }
}

# ---------- 5. 過濾 CDN ----------
Step '過濾 CDN 網段'

$cdnPrefixes = @(
    '104.16.', '104.17.', '104.18.', '104.19.', '104.20.', '104.21.', '104.22.', '104.23.',
    '104.24.', '104.25.', '104.26.', '104.27.',
    '172.64.', '172.65.', '172.66.', '172.67.', '172.68.', '172.69.', '172.70.', '172.71.',
    '13.32.', '13.33.', '13.34.', '13.35.',
    '13.224.', '13.225.', '13.226.', '13.227.',
    '18.65.', '99.84.', '99.85.', '52.84.', '52.85.', '54.230.',
    '2606:4700:', '2600:9000:'
)

$dnsFile = Join-Path $winOut 'dns.txt'
if (Test-Path $dnsFile) {
    $rows = Get-Content $dnsFile -Encoding UTF8
    $cdn = @(); $origin = @()
    foreach ($r in $rows) {
        $isCdn = $false
        foreach ($p in $cdnPrefixes) { if ($r -like "*$p*") { $isCdn = $true; break } }
        if ($isCdn) { $cdn += $r } else { $origin += $r }
    }
    $origin | Set-Content -Path (Join-Path $winOut 'origin-only.txt') -Encoding UTF8
    $cdn    | Set-Content -Path (Join-Path $winOut 'cdn-excluded.txt') -Encoding UTF8
    Ok "非 CDN：$($origin.Count) 筆（origin-only.txt）"
    Ok "CDN 已排除：$($cdn.Count) 筆（cdn-excluded.txt）"
}

# ---------- 6. 過濾靜態與商品頁 ----------
Step '過濾靜態資源與純展示頁'

$httpxFile = Join-Path $winOut 'httpx.txt'
if (Test-Path $httpxFile) {
    $static = '\.(jpg|jpeg|png|gif|svg|ico|webp|css|js|map|woff2?|ttf|eot|mp4|webm|pdf|zip)(\?|$)'
    $keep = @(); $drop = @()
    foreach ($line in (Get-Content $httpxFile -Encoding UTF8)) {
        if ($line -match $static) { $drop += $line } else { $keep += $line }
    }
    # 剔除純商品/分類頁（除非含關鍵字）
    $keep2 = @()
    foreach ($line in $keep) {
        if ($line -match '/(products|categories)/?(\s|$|\?)' -and $line -notmatch 'api|member|user|admin|account|order|cart|checkout|login|auth|upload|export|download|internal|debug') {
            $drop += $line
        } else { $keep2 += $line }
    }
    $keep2 | Set-Content -Path (Join-Path $winOut 'endpoints.txt') -Encoding UTF8
    $drop  | Set-Content -Path (Join-Path $winOut 'excluded.txt') -Encoding UTF8
    Ok "端點：$($keep2.Count) 筆（endpoints.txt）"
    Ok "已剔除：$($drop.Count) 筆（excluded.txt）"
}

# ---------- 7. 摘要 ----------
Step '完成'
Write-Host "  輸出目錄：$winOut" -ForegroundColor White
Get-ChildItem $winOut -File | Sort-Object Name | ForEach-Object {
    Write-Host ("    {0,10:N0}  {1}" -f $_.Length, $_.Name) -ForegroundColor Gray
}
if ($script:errors -gt 0) { Warn "有 $($script:errors) 個工具回報錯誤，請檢查上方訊息" }

Write-Host ''
Write-Host "  複製到專案：Copy-Item '$winOut' 'C:\Users\阿樂\.cline\data\workspaces\chat\strix-zh\engagements\<客戶>' -Recurse -Force" -ForegroundColor DarkGray

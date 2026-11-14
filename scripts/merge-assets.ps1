# 合併 recon 資產清單成單一 txt
#
# 用法：
#   .\scripts\merge-assets.ps1 -List                    # 列出可用的客戶
#   .\scripts\merge-assets.ps1 -Client vghtpe-gov-tw    # 合併該客戶
#   .\scripts\merge-assets.ps1 -ReconDir "C:\path\recon"  # 指定 recon 目錄

param(
    [string]$Client = '',
    [string]$ReconDir = '',
    [string]$OutFile = '',
    [switch]$List
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root = Split-Path -Parent $PSScriptRoot
$engDir = Join-Path $root 'engagements'

function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }

# ---------- 列出可用客戶 ----------
function Get-ReconDirs {
    if (-not (Test-Path $engDir)) { return @() }
    Get-ChildItem $engDir -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $candidate = Join-Path $_.FullName 'out\recon'
            if (Test-Path $candidate) { [pscustomobject]@{ Client = $_.Name; Path = $candidate } }
        }
}

if ($List -or (-not $Client -and -not $ReconDir)) {
    $dirs = Get-ReconDirs
    if ($dirs.Count -eq 0) {
        Warn "找不到任何 recon 結果（預期：engagements\<客戶>\out\recon）"
        exit 1
    }
    Write-Host ''
    Write-Host '  可合併的客戶：' -ForegroundColor White
    for ($i = 0; $i -lt $dirs.Count; $i++) {
        $files = (Get-ChildItem $dirs[$i].Path -File -ErrorAction SilentlyContinue).Count
        Write-Host ("    [{0}] {1}  （{2} 個檔案）" -f ($i + 1), $dirs[$i].Client, $files) -ForegroundColor Gray
    }
    if ($List) { exit 0 }
    Write-Host ''
    $pick = Read-Host '  輸入編號'
    $idx = [int]$pick - 1
    if ($idx -lt 0 -or $idx -ge $dirs.Count) { Bad '編號無效'; exit 1 }
    $ReconDir = $dirs[$idx].Path
    $Client = $dirs[$idx].Client
}

if (-not $ReconDir) {
    $ReconDir = Join-Path (Join-Path (Join-Path $engDir $Client) 'out') 'recon'
}

if (-not (Test-Path $ReconDir)) {
    Bad "找不到 recon 目錄：$ReconDir"
    Bad '請先跑一次「掃描 → recon-only.md」並掛載輸出目錄'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $OutFile = Join-Path $ReconDir 'assets_combined.txt'
}

Write-Host ''
Write-Host "  來源：$ReconDir" -ForegroundColor Gray

# ---------- 讀取三份來源 ----------
$subs = @()
$subFile = Join-Path $ReconDir 'subdomains.json'
if (Test-Path $subFile) {
    try {
        $subs = (Get-Content $subFile -Raw -Encoding UTF8 | ConvertFrom-Json) |
            ForEach-Object { $_.host } | Where-Object { $_ } | Sort-Object -Unique
        Ok "子網域：$($subs.Count) 筆"
    } catch { Warn 'subdomains.json 解析失敗' }
} else {
    Warn '找不到 subdomains.json'
}

$ips = @()
foreach ($name in @('source_ips.txt', 'source_ips_v4.txt', 'source_ips_v6.txt')) {
    $f = Join-Path $ReconDir $name
    if (Test-Path $f) {
        $ips += Get-Content $f -Encoding UTF8 |
            ForEach-Object { ($_ -split "`t")[0].Trim() } |
            Where-Object { $_ -match '^[0-9a-fA-F:\.]+$' }
    }
}
$ips = $ips | Sort-Object -Unique
Ok "來源 IP：$($ips.Count) 筆"

$hv = @()
$hvFile = Join-Path $ReconDir 'high_value.txt'
if (Test-Path $hvFile) {
    $hv = Get-Content $hvFile -Encoding UTF8 | Where-Object { $_ -and $_ -notmatch '^\s*#' }
    Ok "高價值端點：$($hv.Count) 筆"
} else {
    Warn '找不到 high_value.txt'
}

if ($subs.Count -eq 0 -and $ips.Count -eq 0 -and $hv.Count -eq 0) {
    Bad '三份來源都是空的，沒有可合併的內容'
    exit 1
}

# ---------- 產生合併檔 ----------
$domain = ($Client -replace '-', '.')
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

$out = @()
$out += "# $domain 資產清單（Recon Only）"
$out += "# 產生時間：$now"
$out += '# 授權：客戶書面委託，僅供授權範圍內使用'
$out += "# 統計：子網域 $($subs.Count) / 來源 IP $($ips.Count) / 高價值端點 $($hv.Count)"
$out += ''
$out += "## 1. 子網域（$($subs.Count)）"
$out += $subs
$out += ''
$out += "## 2. 來源 IP（$($ips.Count)）"
$out += $ips
$out += ''
$out += "## 3. 高價值端點（$($hv.Count)）"
$out += $hv

[System.IO.File]::WriteAllLines($OutFile, $out, (New-Object System.Text.UTF8Encoding($true)))

Write-Host ''
Ok "已產生：$OutFile"
Write-Host "  共 $($out.Count) 行、$([math]::Round((Get-Item $OutFile).Length/1KB,1)) KB" -ForegroundColor Gray
Write-Host ''

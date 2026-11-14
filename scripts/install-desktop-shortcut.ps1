# 在桌面建立 Strix 啟動捷徑
# 用法：
#   powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-shortcut.ps1
#   pwsh -File .\scripts\install-desktop-shortcut.ps1

$ErrorActionPreference = 'Stop'

try { chcp 65001 | Out-Null } catch { }
try {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

$root = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $root 'scripts\strix-launcher.ps1'

if (-not (Test-Path $launcher)) {
    Write-Host "找不到啟動器：$launcher" -ForegroundColor Red
    Read-Host '按 Enter 結束'
    exit 1
}

$desktop = [Environment]::GetFolderPath('Desktop')
$batPath = Join-Path $desktop 'Strix漢化版.bat'

$bat = @"
@echo off
chcp 65001 >nul
title Strix Launcher
color 0B
echo.
echo   Starting Strix launcher...
echo.

set "PS_EXE=powershell"
where pwsh >nul 2>nul
if %errorlevel%==0 set "PS_EXE=pwsh"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "$launcher"
if errorlevel 1 (
  echo.
  echo   Launcher exited with an error.
  pause
)
"@

# 以 UTF-8（無 BOM）寫入，避免 cmd 讀到 BOM 造成第一行錯誤
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($batPath, $bat, $enc)

Write-Host ''
Write-Host '  已建立桌面捷徑：' -ForegroundColor Green
Write-Host "    $batPath" -ForegroundColor White
Write-Host ''
Write-Host "  它會呼叫：$launcher" -ForegroundColor Gray
Write-Host '  之後直接雙擊桌面的「Strix漢化版」即可。' -ForegroundColor Gray
Write-Host ''
Read-Host '按 Enter 結束'

@echo off
setlocal ENABLEDELAYEDEXPANSION
title S4ssyxd Windows Bootstrap

:: ---------- UI helpers ----------
set INFO=[INFO]
set WARN=[WARN]

echo.
echo %INFO% Checking admin...
:: Require admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% NEQ 0 (
  echo %WARN% Please run this script as Administrator. Right-click the .bat and "Run as administrator".
  pause
  exit /b 1
)

:: ---------- Winget availability ----------
echo.
echo %INFO% Ensuring winget is available...
where winget >nul 2>&1
if %errorlevel% NEQ 0 (
  echo %WARN% winget not found. Make sure you are on Windows 10/11 with Microsoft Store App Installer installed.
  echo      Get it here: Microsoft "App Installer" in Microsoft Store.
  pause
  exit /b 1
)

:: Keep terminal non-interactive where possible
set WINGET_DEF=--accept-package-agreements --accept-source-agreements --silent --disable-interactivity

:: ---------- Base tools ----------
echo.
echo %INFO% Installing base tools: Git, Curl, 7zip, GnuPG
winget install %WINGET_DEF% Git.Git
winget install %WINGET_DEF% curl.curl
winget install %WINGET_DEF% GnuPG.GnuPG
winget install %WINGET_DEF% 7zip.7zip

:: ---------- fastfetch ----------
echo.
echo %INFO% Installing fastfetch...
winget install %WINGET_DEF% fastfetch-cli.Fastfetch

:: ---------- figlet (Windows port) ----------
echo.
echo %INFO% Installing figlet...
winget install %WINGET_DEF% Stamparm.figlet

:: ---------- Node.js LTS ----------
echo.
echo %INFO% Installing Node.js LTS...
winget install %WINGET_DEF% OpenJS.NodeJS.LTS

:: ---------- kubectl ----------
echo.
echo %INFO% Installing kubectl...
winget install %WINGET_DEF% Kubernetes.kubectl

:: ---------- Neovim ----------
echo.
echo %INFO% Installing Neovim...
winget install %WINGET_DEF% Neovim.Neovim

:: ---------- Docker Desktop ----------
echo.
echo %INFO% Installing Docker Desktop...
winget install %WINGET_DEF% Docker.DockerDesktop

:: ---------- LazyVim bootstrap ----------
echo.
echo %INFO% Bootstrapping LazyVim config...
set "NVIM_DIR=%LOCALAPPDATA%\nvim"
if exist "%NVIM_DIR%\init.lua" (
  echo %WARN% "%NVIM_DIR%" already exists; skip LazyVim clone.
) else (
  where git >nul 2>&1
  if %errorlevel% NEQ 0 (
    echo %WARN% Git not found; skipping LazyVim clone.
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass ^
      -Command "git clone https://github.com/LazyVim/starter '%NVIM_DIR%' ; if (Test-Path '%NVIM_DIR%\.git') { Remove-Item -Recurse -Force '%NVIM_DIR%\.git' }"
    echo %INFO% LazyVim ready (open 'nvim' to auto-install plugins).
  )
)

:: ---------- Extra figlet fonts (xero/figlet-fonts) ----------
echo.
echo %INFO% Installing extra figlet fonts...
set "FONTS_TMP=%TEMP%\figlet-fonts-%RANDOM%%RANDOM%"
set "FONTS_TARGET=%ProgramData%\figlet-fonts"
if exist "%FONTS_TMP%" rd /s /q "%FONTS_TMP%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "git clone --depth=1 https://github.com/xero/figlet-fonts.git '%FONTS_TMP%' | Out-Null ; New-Item -ItemType Directory -Force '%FONTS_TARGET%' | Out-Null ; Get-ChildItem -Recurse -Path '%FONTS_TMP%' -Include *.flf | ForEach-Object { Copy-Item $_.FullName -Destination '%FONTS_TARGET%' -Force } ; Remove-Item -Recurse -Force '%FONTS_TMP%'"
if %errorlevel% NEQ 0 (
  echo %WARN% Extra figlet fonts failed to install (skipped).
) else (
  echo %INFO% Extra figlet fonts installed to %FONTS_TARGET%
)

:: Persist FIGLET_FONTDIR for current user
echo.
echo %INFO% Setting FIGLET_FONTDIR user environment variable...
setx FIGLET_FONTDIR "%FONTS_TARGET%" >nul

:: ---------- PowerShell profile banner patch ----------
echo.
echo %INFO% Patching PowerShell profile with random FIGLET banner + fastfetch...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$profileDir = Split-Path -Parent $PROFILE; if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir | Out-Null } ;" ^
  "$markStart = '# >>> S4ssyxd Random Banner >>>'; $markEnd = '# <<< S4ssyxd Random Banner <<<';" ^
  "$profileText = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' };" ^
  "if ($profileText -match [regex]::Escape($markStart)) { $profileText = [regex]::Replace($profileText, [regex]::Escape($markStart) + '.*?' + [regex]::Escape($markEnd), '', 'Singleline') };" ^
  "$bannerBlock = @'
# >>> S4ssyxd Random Banner >>>
function Invoke-Rainbow {
  param([string]$Text)
  $colors = @('DarkRed','Red','DarkYellow','Yellow','DarkGreen','Green','DarkCyan','Cyan','DarkBlue','Blue','DarkMagenta','Magenta')
  $i = 0
  foreach ($ch in $Text.ToCharArray()) {
    $c = $colors[$i %% $colors.Count]
    Write-Host -NoNewline -ForegroundColor $c $ch
    $i++
  }
  Write-Host ''
}
function Get-RandomFigletFont {
  $dir = $env:FIGLET_FONTDIR
  if (-not $dir -or -not (Test-Path $dir)) { return $null }
  $fonts = Get-ChildItem -Path $dir -Filter *.flf -File -ErrorAction SilentlyContinue
  if ($fonts.Count -eq 0) { return $null }
  return ($fonts | Get-Random).FullName
}
function Show-S4Banner {
  Clear-Host
  $sep = ('=' * 80)
  Invoke-Rainbow $sep
  $font = Get-RandomFigletFont
  $fig = 'figlet'
  $text = 's4ssyxd'
  if (Get-Command $fig -ErrorAction SilentlyContinue) {
    if ($font) {
      try { & $fig -f $font $text | ForEach-Object { Invoke-Rainbow $_ } }
      catch { & $fig $text | ForEach-Object { Invoke-Rainbow $_ } }
    } else {
      & $fig $text | ForEach-Object { Invoke-Rainbow $_ }
    }
  } else {
    Invoke-Rainbow $text
  }
  Invoke-Rainbow $sep
  if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch }
  Write-Host ''
}
Show-S4Banner
# <<< S4ssyxd Random Banner <<<
'@;" ^
  "$newProfile = ($profileText.TrimEnd() + \"`n`n\" + $bannerBlock); Set-Content -Path $PROFILE -Value $newProfile -Encoding UTF8;"

if %errorlevel% NEQ 0 (
  echo %WARN% Failed to patch PowerShell profile.
) else (
  echo %INFO% PowerShell profile patched. New terminals will show the banner.
)

:: ---------- Final notes ----------
echo.
echo %INFO% DONE ^(Windows setup complete^) ✅
echo     - Close and re-open PowerShell/Terminal to see the banner.
echo     - Docker Desktop may require sign-out/sign-in or a reboot on first run.

endlocal

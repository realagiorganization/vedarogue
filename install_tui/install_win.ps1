# Requires: Windows 10/11 with winget and/or scoop. Run from an elevated PowerShell if prompted.
# This script installs as many TUIs as reasonably supported on Windows.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log([string]$msg) { Write-Host "[install_tui] $msg" }
function Have([string]$cmd) { Get-Command $cmd -ErrorAction SilentlyContinue | Out-Null }

function TryWingetInstall([string]$id, [string]$name = $null) {
  if (-not (Have 'winget')) { return $false }
  $disp = if ($name) { $name } else { $id }
  try {
    Log "winget install $disp"
    winget install --silent -e --id $id --source winget --accept-package-agreements --accept-source-agreements | Out-Null
    return $true
  } catch { return $false }
}

function EnsureRust() {
  if (Have 'cargo') { return $true }
  if (TryWingetInstall 'Rustlang.Rustup' 'rustup (Rust)') { return $true }
  Log 'Rust (cargo) not found and winget install failed; please install https://rustup.rs and re-run.'
  return $false
}

function EnsureGo() {
  if (Have 'go') { return $true }
  if (TryWingetInstall 'GoLang.Go') { return $true }
  Log 'Go not found and winget install failed; please install https://go.dev/dl and re-run.'
  return $false
}

function EnsurePython() {
  if (Have 'python') { return $true }
  if (TryWingetInstall 'Python.Python.3.12' 'Python 3.12') { return $true }
  if (TryWingetInstall 'Python.Python.3.11' 'Python 3.11') { return $true }
  Log 'Python not found and winget install failed; please install Python and re-run.'
  return $false
}

function EnsureScoop() {
  if (Have 'scoop') { return $true }
  try {
    Log 'Installing Scoop package manager'
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    return (Have 'scoop')
  } catch {
    Log 'Failed to install Scoop automatically. You can install it manually from https://scoop.sh'
    return $false
  }
}

function InstallCargoCrate([string]$crate, [string[]]$flags=@()) {
  if (-not (EnsureRust)) { return $false }
  try {
    Log "cargo install $crate $($flags -join ' ')"
    cargo install @flags $crate | Out-Null
    return $true
  } catch {
    Log "cargo install failed for $crate: $($_.Exception.Message)"
    return $false
  }
}

function PipUserInstall([string]$pkg) {
  if (-not (EnsurePython)) { return $false }
  $pip = if (Have 'pip') { 'pip' } elseif (Have 'pip3') { 'pip3' } else { 'python -m pip' }
  try {
    Log "pip install --user $pkg"
    & $pip install --user --upgrade $pkg | Out-Null
    return $true
  } catch {
    Log "pip install failed for $pkg: $($_.Exception.Message)"
    return $false
  }
}

# --- Installations ---
$results = @{}

# kitty (Windows supported via winget)
$results['kitty'] = TryWingetInstall 'KovidGoyal.Kitty'

# tlock via Scoop bucket
$tlockInstalled = $false
if (Have 'tlock') { $tlockInstalled = $true }
else {
  if (EnsureScoop) {
    try {
      Log 'Adding tlock scoop bucket and installing tlock'
      scoop bucket add tlock https://github.com/eklairs/tlock | Out-Null
      scoop install tlock | Out-Null
      $tlockInstalled = (Have 'tlock')
    } catch {
      Log "scoop install tlock failed: $($_.Exception.Message)"
      $tlockInstalled = $false
    }
  }
}
$results['tlock'] = $tlockInstalled

# gif-for-cli via pip
$results['gif-for-cli'] = PipUserInstall 'gif-for-cli'

# diskonaut (cargo)
$results['diskonaut'] = InstallCargoCrate 'diskonaut'

# ttyper (cargo)
$results['ttyper'] = InstallCargoCrate 'ttyper'

# tray-tui (cargo, prefer --locked)
$ok = InstallCargoCrate 'tray-tui' @('--locked')
if (-not $ok) { $ok = InstallCargoCrate 'tray-tui' }
$results['tray-tui'] = $ok

# xplr (prefer cargo)
$results['xplr'] = InstallCargoCrate 'xplr' @('--locked','--force')

# wego (go)
$wegoOk = $false
if (EnsureGo) {
  try {
    Log 'go install github.com/schachmat/wego@latest'
    go install github.com/schachmat/wego@latest | Out-Null
    $wegoOk = $true
  } catch {
    Log "go install failed for wego: $($_.Exception.Message)"
    $wegoOk = $false
  }
}
$results['wego'] = $wegoOk

# Not supported on Windows: iTerm2, nemu, gdu, ncdu, distrobox-tui
$results['iTerm2'] = $false
$results['nemu'] = $false
$results['gdu'] = $false
$results['ncdu'] = $false
$results['distrobox-tui'] = $false

Log 'Summary:'
$results.GetEnumerator() | Sort-Object Name | ForEach-Object {
  $status = if ($_.Value) { 'OK' } else { 'SKIPPED/FAILED' }
  Write-Host ('  {0,-16} {1}' -f $_.Name, $status)
}

Log 'Done. If new tools are not found, open a new terminal so PATH updates apply.'

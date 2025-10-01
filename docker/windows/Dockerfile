# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

# Prepare a basic developer environment using Scoop (works on Server Core)
RUN Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force ; \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; \
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://get.scoop.sh).Content ; \
    $env:PATH = "$env:USERPROFILE\scoop\shims;$env:PATH" ; \
    scoop install git 7zip less vim wget curl ; \
    scoop install python ; \
    scoop install go ; \
    scoop install rustup ; \
    scoop install mingw ; \
    # Initialize Rust toolchain (GNU to avoid MSVC build tools in container)
    rustup-init.exe -y --default-toolchain stable-gnu ; \
    $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:USERPROFILE\go\bin;$env:USERPROFILE\scoop\shims;$env:PATH" ; \
    [Environment]::SetEnvironmentVariable('PATH', "$env:PATH", 'User') ; \
    Write-Host 'Base tools installed via Scoop.'

WORKDIR C:\work

# Copy repository installer script for convenience (build context root)
COPY install_tui/install_win.ps1 C:/setup/install_win.ps1

# Default shell opens with a hint message
ENTRYPOINT ["powershell", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass"]
CMD ["-NoExit", "-Command", "Write-Host 'Welcome to tui-win container'; Write-Host 'Repo mounted at C:\\work'; if (Test-Path C:\\setup\\install_win.ps1) { Write-Host 'Run C:\\setup\\install_win.ps1 to install tools.' } else { Write-Host 'install_win.ps1 not found in image.' }"]

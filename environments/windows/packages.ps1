$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'install-package.psm1') -Force

if (-not (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue)) {
    $InstallLocation = "$env:LOCALAPPDATA\Programs\oh-my-posh"

    Write-Output "Installing Oh My Posh"
    Install-Package -id JanDeDobbeleer.OhMyPosh -location $InstallLocation
}

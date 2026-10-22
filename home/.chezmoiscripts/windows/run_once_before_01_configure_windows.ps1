$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $env:CHEZMOI_WORKING_TREE 'data/windows/scripts/install-package.psm1') -Force

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Scoop"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

if (-not (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue)) {
    $InstallLocation = "$env:LOCALAPPDATA\Programs\oh-my-posh"

    Write-Output "Installing Oh My Posh"
    Install-Package -id JanDeDobbeleer.OhMyPosh -location $InstallLocation
    Add-MpPreference -ExclusionPath $InstallLocation
}


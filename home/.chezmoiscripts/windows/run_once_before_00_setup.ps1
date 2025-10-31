if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Output "========================="
    Write-Output "Installing WinGet"
    Write-Output "========================="
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Write-Output "========================="
    Write-Output "Installing Scoop"
    Write-Output "========================="
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

if (-not (Test-Path "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe" -PathType Leaf)) {
    Write-Output "========================="
    Write-Output "Installing UniGetUI"
    Write-Output "========================="
    winget install `
        --exact `
        --id MartiCliment.UniGetUI `
        --source winget `
        --accept-source-agreements `
        --disable-interactivity `
        --silent `
        --accept-package-agreements `
        --force
}

# Apply settings
. "$env:CHEZMOI_WORKING_TREE/data/windows/scripts/apply-settings.ps1"


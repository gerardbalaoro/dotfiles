. $env:CHEZMOI_SCRIPTS\windows\scripts\install-package.psm1

if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing WinGet"
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Scoop"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

if (-not (Get-Command "mise" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Mise"
    Install-Package -id jdx.mise
}

if (-not (Get-Command "clink" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Clink"
    Install-Package -id chrisant996.Clink
}

if (-not (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue)) {
    $InstallLocation = "$env:LOCALAPPDATA\Programs\oh-my-posh"

    Write-Output "Installing Oh My Posh"
    Install-Package -id JanDeDobbeleer.OhMyPosh -location $InstallLocation
    Add-MpPreference -ExclusionPath $InstallLocation
}

Install-Package -id AgileBits.1Password
Install-Package -id AgileBits.1Password.CLI

Install-Package -id Git.Git
Install-Package -id Microsoft.WindowsTerminal
Install-Package -id Microsoft.VisualStudioCode

Install-Package -id M2Team.NanaZip
Install-Package -id Starpine.Screenbox
Install-Package -id AntibodySoftware.WizTree
Install-Package -id LesFerch.WinSetView

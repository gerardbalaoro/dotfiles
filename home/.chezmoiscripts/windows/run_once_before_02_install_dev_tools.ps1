. $env:CHEZMOI_SCRIPTS\windows\scripts\install-package.psm1

if (-not (Get-Command "mise" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Mise"
    Install-Package -id jdx.mise
}

Install-Package -id Git.Git
Install-Package -id GitHub.CLI
Install-Package -id Microsoft.WindowsTerminal
Install-Package -id Microsoft.VisualStudioCode

. $env:CHEZMOI_SCRIPTS\windows\scripts\install-package.psm1

if (-not (Get-Command "mise" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Mise"
    Install-Package -id jdx.mise
}

if (-not (Get-Command "clink" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Clink"
    Install-Package -id chrisant996.Clink
}

Install-Package -id Git.Git
Install-Package -id Microsoft.WindowsTerminal
Install-Package -id Microsoft.VisualStudioCode

if (-not (Test-Path "$env:USERPROFILE\.vite-plus")) {
    Write-Output "Installing Vite+"
    $env:VP_NODE_MANAGER = "no"
    powershell -ExecutionPolicy ByPass -c "irm https://vite.plus/ps1 | iex"
}

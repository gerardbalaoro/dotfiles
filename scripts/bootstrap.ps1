$ErrorActionPreference = 'Stop'
$repositoryUrl = if ($env:DOTFILES_REPOSITORY) { $env:DOTFILES_REPOSITORY } else { 'https://github.com/gerardbalaoro/dotfiles.git' }
$env:MISE_AUTO_ENV = 'true'
$sourceDirectory = $null
if ($PSScriptRoot) {
    $candidate = Split-Path -Parent $PSScriptRoot
    if ((Test-Path (Join-Path $candidate 'mise.toml')) -and (Test-Path (Join-Path $candidate 'layers/common/home'))) {
        $sourceDirectory = $candidate
    }
}

function Update-ProcessPath {
    $env:Path = @(
        $env:Path
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    ) -join ';'
    $env:Path = ($env:Path -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Install-Prerequisite {
    param([string]$Command, [string]$Package)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        & winget install --id $Package --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "Failed to install $Package" }
        Update-ProcessPath
    }
}

function Invoke-Bootstrap {
    param([string[]]$BootstrapArguments = @())
    if ($sourceDirectory) {
        & mise -C $sourceDirectory bootstrap @BootstrapArguments
    } else {
        & mise bootstrap --from $repositoryUrl @BootstrapArguments
    }
    if ($LASTEXITCODE -ne 0) { throw 'Bootstrap failed' }
}

Update-ProcessPath
Install-Prerequisite -Command git -Package Git.Git
Install-Prerequisite -Command mise -Package jdx.mise
$miseVersion = (& mise --version) -split ' ' | Select-Object -First 1
if ([version]$miseVersion -lt [version]'2026.10.21') {
    & winget upgrade --id jdx.mise --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw 'mise 2026.10.21 or newer is required' }
    Update-ProcessPath
}

if ($sourceDirectory) {
    & mise -C $sourceDirectory trust
    if ($LASTEXITCODE -ne 0) { throw 'Could not trust the local checkout' }
}
Invoke-Bootstrap -BootstrapArguments @('--skip', 'dotfiles,task', '--update')
Update-ProcessPath

if (-not (Get-Command op -ErrorAction SilentlyContinue)) {
    throw '1Password CLI is not available on PATH after provisioning'
}
while ($true) {
    $accessible = $false
    try {
        & op read 'op://Personal/SSH Key/email' 2>$null | Out-Null
        $accessible = $LASTEXITCODE -eq 0
    } catch { }
    if ($accessible) { break }
    Write-Host 'Sign in to 1Password and enable CLI integration.'
    Read-Host 'Once Personal/SSH Key is accessible, press Enter to retry' | Out-Null
}

Invoke-Bootstrap
Write-Host 'Setup complete. Open a new terminal to activate your tools.'

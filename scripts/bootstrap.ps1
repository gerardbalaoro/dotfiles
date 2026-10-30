$ErrorActionPreference = 'Stop'
$repositoryUrl = if ($env:DOTFILES_REPOSITORY) { $env:DOTFILES_REPOSITORY } else { 'https://github.com/gerardbalaoro/dotfiles.git' }
$env:MISE_AUTO_ENV = 'true'
$minimumMiseVersion = [version]'2026.10.21'
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

function Set-MisePath {
    param([string]$Directory)
    # Preserve expandable PATH entries while moving an existing directory first.
    $environmentKey = Get-Item -LiteralPath 'HKCU:\Environment'
    $userPath = [string]$environmentKey.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $otherPaths = @($userPath -split ';' | Where-Object {
        $_ -and $_.Replace('/', '\').TrimEnd('\') -ine $Directory.Replace('/', '\').TrimEnd('\')
    })
    Set-ItemProperty -LiteralPath 'HKCU:\Environment' -Name Path -Type ExpandString -Value ((@($Directory) + $otherPaths) -join ';')
    $env:Path = "$Directory;$env:Path"

    # Notify Explorer so terminals it starts receive the reordered user PATH.
    if (-not ('Dotfiles.Environment' -as [type])) {
        Add-Type -Namespace Dotfiles -Name Environment -MemberDefinition '[DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);'
    }
    $result = [UIntPtr]::Zero
    [void][Dotfiles.Environment]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
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
$miseVersion = if (Get-Command mise -ErrorAction SilentlyContinue) {
    (& mise --version) -split ' ' | Select-Object -First 1
} else { '0.0.0' }
if ([version]$miseVersion -lt $minimumMiseVersion) {
    # WinGet can lag the min_version in mise.toml; use official releases.
    Invoke-RestMethod -Uri https://mise.run/powershell | Invoke-Expression
    Update-ProcessPath
    $miseInstallPath = if ($env:MISE_INSTALL_PATH) { $env:MISE_INSTALL_PATH } else { Join-Path $HOME '.local/bin/mise.exe' }
    Set-MisePath -Directory (Split-Path -Parent $miseInstallPath)
}
$miseVersion = (& mise --version) -split ' ' | Select-Object -First 1
if ($LASTEXITCODE -ne 0 -or [version]$miseVersion -lt $minimumMiseVersion) {
    throw "mise $minimumMiseVersion or newer is required; check which mise is on PATH"
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

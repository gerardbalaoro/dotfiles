param(
    [switch]$Connect,
    [switch]$Once,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$BootstrapArguments
)
if ($Connect -and $Once) { throw 'Choose either -Connect or -Once' }
$ErrorActionPreference = 'Stop'
$repositoryUrl = if ($env:DOTFILES_REPOSITORY) { $env:DOTFILES_REPOSITORY } else { 'https://github.com/gerardbalaoro/dotfiles.git' }
$env:MISE_AUTO_ENV = 'true'
$minimumMiseVersion = [version]'2026.11.7'
$miseDataDirectory = if ($env:MISE_DATA_DIR) { $env:MISE_DATA_DIR }
    elseif ($env:XDG_DATA_HOME) { Join-Path $env:XDG_DATA_HOME 'mise' }
    else { Join-Path $env:LOCALAPPDATA 'mise' }
$consumerDirectory = Join-Path $miseDataDirectory 'bootstrap-repo'
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

$miseConfigDirectory = if ($env:MISE_CONFIG_DIR) { $env:MISE_CONFIG_DIR }
    elseif ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'mise' }
    else { Join-Path $HOME '.config/mise' }
$item = Get-Item -LiteralPath $miseConfigDirectory -Force -ErrorAction SilentlyContinue
if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    $targets = @($item.Target)
    if ($targets.Count -ne 1 -or -not $targets[0]) { throw 'Cannot resolve global mise config link' }
    $target = [string]$targets[0]
    if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path (Split-Path -Parent $miseConfigDirectory) $target
    }
    if ($Once -or -not (Test-Path -LiteralPath $target -PathType Container) -or
        [IO.Path]::GetFullPath($target).TrimEnd('\', '/') -ine [IO.Path]::GetFullPath($consumerDirectory).TrimEnd('\', '/')) {
        throw 'Global mise config links elsewhere or is unavailable; resolve that connection before installing'
    }
}
# An empty directory prevents the caller's project configuration from loading.
$runDirectory = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $runDirectory | Out-Null
try {
    & mise -C $runDirectory bootstrap --from $repositoryUrl --from-dir $consumerDirectory --only plugins --yes --update
    if ($LASTEXITCODE -ne 0) { throw 'Could not fetch the consumer checkout' }
    if (-not $Once) {
        if ($item -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            $backup = "$miseConfigDirectory.backup.$(Get-Date -Format yyyyMMddHHmmss)"
            if (Test-Path -LiteralPath $backup) { throw "Backup already exists: $backup" }
            # Only environment selection is portable without interpreting existing TOML.
            $selectionSource = Join-Path $miseConfigDirectory 'miserc.local.toml'
            if (-not (Test-Path -LiteralPath $selectionSource)) {
                $selectionSource = Join-Path $miseConfigDirectory 'miserc.toml'
            }
            if (Test-Path -LiteralPath $selectionSource) {
                $destination = Join-Path $consumerDirectory 'miserc.local.toml'
                if (Test-Path -LiteralPath $destination) {
                    if ((Get-Content -LiteralPath $selectionSource -Raw) -cne (Get-Content -LiteralPath $destination -Raw)) {
                        throw "Environment selection already exists: $destination"
                    }
                } else {
                    Copy-Item -LiteralPath $selectionSource -Destination $destination
                }
            }
            Move-Item -LiteralPath $miseConfigDirectory -Destination $backup
            Write-Host "Previous mise configuration saved to $backup"
            Write-Host 'Previous settings are not activated automatically. Review these files before transferring custom settings; adjust relative paths:'
            Get-ChildItem -LiteralPath $backup -Recurse -File -Force | ForEach-Object { Write-Host $_.FullName }
        }
        $machineConfig = Join-Path $consumerDirectory 'miserc.local.toml'
    } else {
        $machineConfig = Join-Path $miseConfigDirectory 'miserc.local.toml'
    }
    if (-not (Test-Path -LiteralPath $machineConfig)) {
        $desktop = (Test-Path (Join-Path $env:SystemRoot 'explorer.exe')) -and
            -not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ContainerType')
        $selection = if ($desktop) { 'env = ["desktop"]' } else { 'env = []' }
        New-Item -ItemType Directory -Path (Split-Path -Parent $machineConfig) -Force | Out-Null
        Set-Content -LiteralPath $machineConfig -Value $selection -Encoding Ascii
    }
    if ($Once) {
        $previousConfigDirectory = $env:MISE_CONFIG_DIR
        try {
            Copy-Item -LiteralPath $machineConfig -Destination (Join-Path $consumerDirectory 'miserc.local.toml') -Force
            $env:MISE_CONFIG_DIR = $consumerDirectory
            & mise -C $consumerDirectory -E once bootstrap --yes @BootstrapArguments
            if ($LASTEXITCODE -ne 0) { throw 'Bootstrap failed' }
        } finally {
            $env:MISE_CONFIG_DIR = $previousConfigDirectory
        }
    } else {
        & mise -C $runDirectory bootstrap --from $repositoryUrl --from-dir $consumerDirectory --config-dir . --yes --update @BootstrapArguments
    }
    if ($LASTEXITCODE -ne 0) { throw 'Bootstrap failed' }
    Write-Host 'Setup complete. Open a new terminal, then run mise run dotfiles:identity to restore Git identity and SSH keys.'

} finally {
    Remove-Item -LiteralPath $runDirectory -Recurse -Force
}

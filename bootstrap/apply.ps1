$ErrorActionPreference = 'Stop'

# WinGet may have installed Git or 1Password since this process started.
# Keep mise's tool paths first, then pick up newly registered system/user paths.
$env:Path = @(
    $env:Path
    [Environment]::GetEnvironmentVariable('Path', 'Machine')
    [Environment]::GetEnvironmentVariable('Path', 'User')
    (Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\bin')
) -join ';'

$repository = Split-Path -Parent $PSScriptRoot
& chezmoi init --source $repository --apply
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

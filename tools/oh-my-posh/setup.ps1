$ErrorActionPreference = 'Stop'
$env:Path = @($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User'), (Join-Path $env:LOCALAPPDATA 'Programs/oh-my-posh/bin')) -join ';'
$repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$stateRoot = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $env:LOCALAPPDATA 'state' }
$state = Join-Path $stateRoot 'dotfiles'
$marker = Join-Path $state 'fonts.sha256'

if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    Write-Host 'Fetching font archives with Git LFS...'
    git -C $repository lfs install --local
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS initialization failed' }
    git -C $repository lfs pull
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS font download failed' }

    $fonts = @("CommitMono", "CommitMono_NerdFont")
    $paths = @($PSCommandPath) + @($fonts | ForEach-Object { Join-Path $repository "tools/oh-my-posh/fonts/$_.zip" })
    $checksum = ($paths | ForEach-Object { Get-FileHash -LiteralPath $_ -Algorithm SHA256 } | ForEach-Object { $_.Hash }) -join "`n"
    if ((Test-Path $marker) -and ((Get-Content $marker -Raw).Trim() -eq $checksum)) {
        Write-Host 'Fonts are already installed.'
        return
    }

    # Older releases need --headless; version 30 removed the font installer TUI.
    $fontHelp = (& oh-my-posh font install --help) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect Oh My Posh font installation options' }
    $fontOptions = @()
    if ($fontHelp.Contains('--headless')) {
        $fontOptions += '--headless'
    } elseif (-not $fontHelp.Contains('font install <font>')) {
        throw 'Update Oh My Posh to a release with noninteractive font installation.'
    }

    foreach ($font in $fonts) {
        $fontPath = Join-Path $repository "tools/oh-my-posh/fonts/$font.zip"
        if (Test-Path $fontPath) {
            Write-Host "Installing $font..."
            oh-my-posh font install $fontPath @fontOptions
            if ($LASTEXITCODE -ne 0) { throw "Font installation failed: $font" }
        } else {
            throw "Font archive missing: $fontPath"
        }
    }
    New-Item -ItemType Directory -Path $state -Force | Out-Null
    Set-Content -Path $marker -Value $checksum
} else {
    throw 'oh-my-posh not found; run mise bootstrap to install prerequisites'
}

$ErrorActionPreference = 'Stop'
$env:Path = @($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User'), (Join-Path $env:LOCALAPPDATA 'Programs/oh-my-posh/bin')) -join ';'
$repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$stateRoot = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $env:LOCALAPPDATA 'state' }
$state = Join-Path $stateRoot 'dotfiles'
$marker = Join-Path $state 'fonts.sha256'

if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    git -C $repository lfs install --local
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS initialization failed' }
    git -C $repository lfs pull
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS font download failed' }

    $fonts = @("CommitMono", "CommitMono_NerdFont")
    $paths = @($PSCommandPath) + @($fonts | ForEach-Object { Join-Path $repository "layers/common/fonts/$_.zip" })
    $checksum = ($paths | ForEach-Object { Get-FileHash -LiteralPath $_ -Algorithm SHA256 } | ForEach-Object { $_.Hash }) -join "`n"
    if ((Test-Path $marker) -and ((Get-Content $marker -Raw).Trim() -eq $checksum)) {
        return
    }
    foreach ($font in $fonts) {
        $fontPath = Join-Path $repository "layers/common/fonts/$font.zip"
        if (Test-Path $fontPath) {
            oh-my-posh font install $fontPath
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

$ErrorActionPreference = 'Stop'

if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    chezmoi git lfs install
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS initialization failed' }
    chezmoi git lfs pull
    if ($LASTEXITCODE -ne 0) { throw 'Git LFS font download failed' }

    $fonts = @("CommitMono", "CommitMono_NerdFont")
    foreach ($font in $fonts) {
        $fontPath = Join-Path $env:CHEZMOI_WORKING_TREE "data/fonts/$font.zip"
        if (Test-Path $fontPath) {
            oh-my-posh font install $fontPath
            if ($LASTEXITCODE -ne 0) { throw "Font installation failed: $font" }
        } else {
            throw "Font archive missing: $fontPath"
        }
    }
} else {
    throw 'oh-my-posh not found; run mise bootstrap to install prerequisites'
}

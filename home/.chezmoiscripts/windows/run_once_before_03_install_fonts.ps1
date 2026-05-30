if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    chezmoi git lfs install
    chezmoi git lfs pull

    $fonts = @("CommitMono")
    foreach ($font in $fonts) {
        $fontPath = Join-Path $env:CHEZMOI_WORKING_TREE "data/fonts/$font.zip"
        if (Test-Path $fontPath) {
            oh-my-posh font install $fontPath
        }
    }
} else {
    Write-Host "oh-my-posh not found, skipping font installation"
}
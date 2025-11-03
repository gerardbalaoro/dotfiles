if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    chezmoi git lfs install
    chezmoi git lfs pull
    oh-my-posh font install "$env:CHEZMOI_WORKING_TREE/data/fonts/Monaspace Neon.zip"
} else {
    Write-Host "oh-my-posh not found, skipping font installation"
}
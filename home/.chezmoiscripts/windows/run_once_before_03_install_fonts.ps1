if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    chezmoi git lfs install
    chezmoi git lfs pull
    oh-my-posh font install "$env:CHEZMOI_WORKING_TREE/data/fonts/GeistMonoNF.zip"
    oh-my-posh font install "$env:CHEZMOI_WORKING_TREE/data/fonts/MonaspaceNeonNF.zip"
} else {
    Write-Host "oh-my-posh not found, skipping font installation"
}
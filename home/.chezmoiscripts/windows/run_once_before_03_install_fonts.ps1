if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
    chezmoi git lfs install
    chezmoi git lfs pull
    Get-ChildItem "$env:CHEZMOI_WORKING_TREE/data/fonts/*.zip" | ForEach-Object {
        oh-my-posh font install $_.FullName
    }
} else {
    Write-Host "oh-my-posh not found, skipping font installation"
}
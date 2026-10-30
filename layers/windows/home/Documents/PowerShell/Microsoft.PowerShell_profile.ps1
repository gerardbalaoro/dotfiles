# Aliases
Set-Alias -Name which -Value where.exe

# Activate mise before loading integrations that use managed tools.
if (Get-Command mise -ErrorAction SilentlyContinue) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}

# Oh-My-Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config (Join-Path $HOME ".config/oh-my-posh/main.omp.json") | Invoke-Expression
}

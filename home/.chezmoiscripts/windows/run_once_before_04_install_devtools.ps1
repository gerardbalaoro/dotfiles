Import-Module "$env:CHEZMOI_WORKING_TREE/data/windows/scripts/install-bundle.psm1"
Import-Module "$env:CHEZMOI_WORKING_TREE/data/windows/scripts/install-package.psm1"

# Install devtools bundle
Install-Bundle -BundlePath "$env:CHEZMOI_WORKING_TREE/data/windows/packages/devtools.ubundle" -Unattended

# Install pnpm
Install-Script -exe "pnpm" -uri "https://get.pnpm.io/install.ps1"
sudo powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath $(pnpm store path)"

# Install bun
Install-Script -exe "bun" -uri "https://bun.sh/install.ps1"

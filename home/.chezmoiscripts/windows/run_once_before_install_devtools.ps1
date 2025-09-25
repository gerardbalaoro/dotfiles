. "$env:CHEZMOI_WORKING_TREE/scripts/windows/install-helpers.ps1"

Install-Package "CoreyButler.NVMforWindows"
Install-Script -exe "pnpm" -uri "https://get.pnpm.io/install.ps1"
Install-Script -exe "bun" -uri "https://bun.sh/install.ps1"

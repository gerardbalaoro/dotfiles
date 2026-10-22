# The Store app is separate from the Codex CLI managed by mise.
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $env:CHEZMOI_WORKING_TREE 'data/windows/scripts/install-package.psm1') -Force
Install-Package -id 9PLM9XGG6VKS -source msstore

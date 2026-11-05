$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'settings.ps1')

# The Store app is separate from the Codex CLI managed by mise.
Import-Module (Join-Path $PSScriptRoot 'install-package.psm1') -Force
Install-Package -id 9PLM9XGG6VKS -source msstore

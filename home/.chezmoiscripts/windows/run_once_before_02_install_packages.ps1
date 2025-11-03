# Install essentials bundle
Import-Module "$env:CHEZMOI_WORKING_TREE/data/windows/scripts/install-bundle.psm1"
Install-Bundle -BundlePath "$env:CHEZMOI_WORKING_TREE/data/windows/packages/essentials.ubundle" -Unattended

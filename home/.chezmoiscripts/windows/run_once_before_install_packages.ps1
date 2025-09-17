# This script installs clink and oh-my-posh using winget.
# It assumes winget is already installed on your system.
# If winget is missing, the script will exit with an error.

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed. Please install winget first."
    exit 1
}

function Check-Package {
    param (
        [string]$PackageId
    )
    # Use winget list with the exact flag.
    $result = winget list --id $PackageId -e 2>$null
    # If the command output contains the package id, assume it's installed.
    return $result -match $PackageId
}

function Install-Package {
    param (
        [string]$id
    )
    if (Check-Package $id) {
        Write-Output "$id is already installed."
    } else {
        Write-Output "Installing $id..."
        winget install --id=$id -e --silent --accept-package-agreements --accept-source-agreements
    }
}

Install-Package 'chrisant996.Clink'
Install-Package 'JanDeDobbeleer.OhMyPosh'
Install-Package 'AgileBits.1Password.CLI'

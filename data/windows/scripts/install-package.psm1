function Get-Package {
    param (
        [string]$PackageId
    )

    $result = winget list --id $PackageId -e 2>$null
    return $result -match $PackageId
}

function Install-Package {
    param (
        [string]$id
        [string]$location = $null
    )

    if (-not (Get-Package $id)) {
        if ($location) {
            winget install --id=$id -e --silent --accept-package-agreements --accept-source-agreements --location=$location
        } else {
            winget install --id=$id -e --silent --accept-package-agreements --accept-source-agreements
        }
    }
}

function Install-Script {
    param (
        [string]$exe,
        [string]$uri
    )

    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
        powershell -ExecutionPolicy ByPass -c "irm $uri | iex"
    }
}

Export-ModuleMember -Function Install-Package, Install-Script

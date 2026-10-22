function Get-Package {
    param (
        [string]$PackageId,
        [string]$Source = $null
    )

    $listArgs = @('list', '--id', $PackageId, '--exact')
    if ($Source) { $listArgs += @('--source', $Source) }
    & winget @listArgs *> $null
    return $LASTEXITCODE -eq 0
}

function Install-Package {
    param (
        [string]$id,
        [string]$location = $null,
        [string]$source = $null
    )

    if (-not (Get-Package -PackageId $id -Source $source)) {
        $installArgs = @('install', '--id', $id, '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements')
        if ($location) { $installArgs += @('--location', $location) }
        if ($source) { $installArgs += @('--source', $source) }
        & winget @installArgs
        if ($LASTEXITCODE -ne 0) {
            throw "WinGet failed to install $id (exit $LASTEXITCODE)"
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

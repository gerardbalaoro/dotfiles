function Read-Bundle {
    <#
    .SYNOPSIS
        Reads and parses a UniGetUI bundle file
    
    .PARAMETER Path
        Path to the .ubundle file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        throw "Bundle file not found at: $Path"
    }
    
    try {
        $content = Get-Content $Path -Raw | ConvertFrom-Json
        return $content
    }
    catch {
        throw "Failed to parse bundle file: $_"
    }
}

function Get-InstallCommand {
    <#
    .SYNOPSIS
        Builds an installation command for a package
    
    .PARAMETER Package
        Package object from the bundle file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Package
    )
    
    $id = $Package.Id
    $source = $Package.Source.ToLower()
    $manager = $Package.ManagerName
    
    # Determine package manager and build appropriate command
    switch ($manager) {
        "Winget" {
            # WinGet command
            $cmd = "winget.exe install --id `"$id`" --exact --source $source"
            $cmd += " --accept-source-agreements --disable-interactivity --silent --accept-package-agreements"
            
            # Handle installation options
            if ($Package.InstallationOptions) {
                $options = $Package.InstallationOptions
                
                # Custom install location
                if ($options.CustomInstallLocation) {
                    $location = $options.CustomInstallLocation
                    # Don't expand environment variables - let winget handle it
                    $cmd += " --location `"$location`""
                }
            }
        }
        
        "Scoop" {
            # Scoop command
            $cmd = "scoop install $id"
        }
        
        "Chocolatey" {
            # Chocolatey command
            $cmd = "choco install $id -y"
            
            # Handle installation options
            if ($Package.InstallationOptions) {
                $options = $Package.InstallationOptions
                
                # Custom install location
                if ($options.CustomInstallLocation) {
                    $location = $options.CustomInstallLocation
                    $cmd += " --install-directory=`"$location`""
                }
            }
        }
        
        default {
            throw "Unsupported package manager: $manager"
        }
    }
    
    return $cmd
}

function Install-Bundle {
    <#
    .SYNOPSIS
        Installs packages from a UniGetUI bundle file
    
    .DESCRIPTION
        Reads a .ubundle file and installs all packages defined within it.
        Supports custom installation locations, pre/post-install commands,
        and multiple package sources (winget, msstore).
    
    .PARAMETER BundlePath
        Path to the .ubundle file to install
    
    .PARAMETER Unattended
        Skip confirmation prompts for unattended installation
    
    .PARAMETER ShowBanner
        Display the installer banner (default: true)
    
    .EXAMPLE
        Install-Bundle -BundlePath ".\essentials.ubundle"
        
    .EXAMPLE
        Install-Bundle -BundlePath ".\devtools.ubundle" -Unattended
        
    .EXAMPLE
        Install-Bundle -BundlePath "C:\bundles\custom.ubundle" -Unattended -ShowBanner:$false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$BundlePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Unattended
    )
    
    # Load and validate bundle
    Write-Host "Loading bundle file: $BundlePath" -ForegroundColor Cyan
    try {
        $bundle = Read-Bundle -Path $BundlePath
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return 1
    }
    
    Write-Host "Bundle version: $($bundle.export_version)" -ForegroundColor Gray
    Write-Host "Packages found: $($bundle.packages.Count)" -ForegroundColor Gray
    Write-Host ""
    
    # Process packages
    $packages = $bundle.packages
    
    if ($packages.Count -eq 0) {
        Write-Host "No packages found in bundle file." -ForegroundColor Yellow
        return 0
    }
    
    Write-Host "This script will attempt to install the following packages:"
    foreach ($pkg in $packages) {
        $managerDisplay = switch ($pkg.ManagerName) {
            "Winget" { 
                if ($pkg.Source -eq "msstore") { "Microsoft Store" } 
                else { "WinGet" }
            }
            "Scoop" { "Scoop" }
            "Chocolatey" { "Chocolatey" }
            default { $pkg.ManagerName }
        }
        Write-Host "  - $($pkg.Name) from $managerDisplay"
    }
    Write-Host ""
    
    if (-not $Unattended) { 
        pause 
    }
    
    Clear-Host
    
    $success_count = 0
    $failure_count = 0
    $commands_run = 0
    $results = ""
    
    foreach ($pkg in $packages) {
        Write-Host ("=" * 60)
        Write-Host "$($pkg.Name)" -ForegroundColor Cyan
        Write-Host ("=" * 60)
        
        # Pre-install command
        if ($pkg.InstallationOptions -and $pkg.InstallationOptions.PreInstallCommand) {
            $preCmd = $pkg.InstallationOptions.PreInstallCommand
            Write-Host "Running pre-install command..." -ForegroundColor Yellow
            Write-Host "  $preCmd" -ForegroundColor Gray
            
            try {
                Invoke-Expression $preCmd
                if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
                    Write-Host "  [WARN] Pre-install command returned exit code: $LASTEXITCODE" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "  [WARN] Pre-install command failed: $_" -ForegroundColor Yellow
            }
        }
        
        # Build and run install command
        try {
            $installCmd = Get-InstallCommand -Package $pkg
        }
        catch {
            Write-Host "[ FAIL ] $($pkg.Name) - $_" -ForegroundColor Red
            $failure_count++
            $results += "$([char]0x1b)[31m[ FAIL ] $($pkg.Name) - $_`n"
            $commands_run++
            continue
        }
        
        Write-Host "Installing package..." -ForegroundColor Yellow
        Write-Host "  $installCmd" -ForegroundColor Gray
        
        # Execute command based on package manager
        if ($pkg.ManagerName -in @("Scoop", "Chocolatey")) {
            # Execute directly in PowerShell for Scoop/Chocolatey
            Invoke-Expression $installCmd
            $installExitCode = $LASTEXITCODE
        }
        else {
            # Execute via cmd.exe for WinGet
            cmd.exe /C $installCmd
            $installExitCode = $LASTEXITCODE
        }
        
        if ($installExitCode -eq 0) {
            Write-Host "[  OK  ] $($pkg.Name)" -ForegroundColor Green
            $success_count++
            $results += "$([char]0x1b)[32m[  OK  ] $($pkg.Name)`n"
        }
        else {
            Write-Host "[ FAIL ] $($pkg.Name) (Exit code: $installExitCode)" -ForegroundColor Red
            $failure_count++
            $results += "$([char]0x1b)[31m[ FAIL ] $($pkg.Name) (Exit code: $installExitCode)`n"
        }
        
        # Post-install command
        if ($pkg.InstallationOptions -and $pkg.InstallationOptions.PostInstallCommand) {
            $postCmd = $pkg.InstallationOptions.PostInstallCommand
            Write-Host "Running post-install command..." -ForegroundColor Yellow
            Write-Host "  $postCmd" -ForegroundColor Gray
            
            try {
                Invoke-Expression $postCmd
                if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
                    Write-Host "  [WARN] Post-install command returned exit code: $LASTEXITCODE" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "  [WARN] Post-install command failed: $_" -ForegroundColor Yellow
            }
        }
        
        $commands_run++
    }
    
    Write-Host ""
    Write-Host "========================================================"
    Write-Host "                  OPERATION SUMMARY"
    Write-Host "========================================================"
    Write-Host "Total packages processed: $commands_run"
    Write-Host "Successful: $success_count"
    Write-Host "Failed: $failure_count"
    Write-Host ""
    Write-Host "Details:"
    Write-Host "$results$([char]0x1b)[37m"
    Write-Host "========================================================"
    
    if ($failure_count -gt 0) {
        Write-Host "Some packages failed to install. Please check the log above." -ForegroundColor Yellow
    }
    else {
        Write-Host "All packages installed successfully!" -ForegroundColor Green
    }
    Write-Host ""
    
    if (-not $Unattended) { 
        pause 
    }
}

Export-ModuleMember -Function Install-Bundle

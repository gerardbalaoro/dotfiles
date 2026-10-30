$ErrorActionPreference = 'Stop'

# Run elevated settings only when this script changes.
$state = Join-Path $env:LOCALAPPDATA 'mise/dotfiles'
$marker = Join-Path $state 'windows-settings.sha256'
$checksum = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
if ((Test-Path $marker) -and ((Get-Content $marker -Raw).Trim() -eq $checksum)) {
    return
}

function Enable-TaskbarEndTask() {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
    $name = "TaskbarEndTask"
    $value = 1

    # Ensure the registry key exists
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Set the property, creating it if it doesn't exist
    New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null
}

function Enable-ShowFileExtensions() {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $name = "HideFileExt"
    $value = 0

    # Ensure the registry key exists
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Set the property, creating it if it doesn't exist
    New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null
}

function Enable-DeveloperMode() {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    $name1 = "AllowDevelopmentWithoutDevLicense"
    $name2 = "AllowAllTrustedApps"
    $value = 1

    # Ensure the registry key exists
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Set the properties, creating them if they don't exist
    New-ItemProperty -Path $path -Name $name1 -PropertyType DWord -Value $value -Force | Out-Null
    New-ItemProperty -Path $path -Name $name2 -PropertyType DWord -Value $value -Force | Out-Null
}

function Enable-DefaultTerminal() {
    $path = "HKCU:\Console\%%Startup"

    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Set Windows Terminal as default
    Set-ItemProperty -Path $path -Name "DelegationConsole" -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
    Set-ItemProperty -Path $path -Name "DelegationTerminal" -Value "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
}


if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "This script needs to be run as Administrator. Attempting to relaunch."
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        }
        elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        }
        elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    $script = "& { & `'$($PSCommandPath)`' $($argList -join ' ') }"
    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $process = Start-Process $powershellCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Windows settings failed (exit $($process.ExitCode))" }
    return
}

if (Get-Command "sudo" -ErrorAction SilentlyContinue) {
    sudo config --enable normal
    if ($LASTEXITCODE -ne 0) { throw 'Windows sudo configuration failed' }
}

if (Get-Command "powercfg" -ErrorAction SilentlyContinue) {
    powercfg /hibernate on
    if ($LASTEXITCODE -ne 0) { throw 'Enabling hibernation failed' }
}

Enable-DefaultTerminal
Enable-DeveloperMode
Enable-ShowFileExtensions
Enable-TaskbarEndTask

$poshLocation = Join-Path $env:LOCALAPPDATA 'Programs/oh-my-posh'
if ((Test-Path $poshLocation) -and (Get-Command Add-MpPreference -ErrorAction SilentlyContinue)) {
    $exclusions = (Get-MpPreference).ExclusionPath
    if ($exclusions -notcontains $poshLocation) {
        Add-MpPreference -ExclusionPath $poshLocation
    }
}

New-Item -ItemType Directory -Path $state -Force | Out-Null
Set-Content -Path $marker -Value $checksum

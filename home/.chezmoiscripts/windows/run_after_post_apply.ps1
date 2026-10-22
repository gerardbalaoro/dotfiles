$ErrorActionPreference = 'Stop'

# Keep direct chezmoi apply useful after global tool declarations change.
if (Get-Command "mise" -ErrorAction SilentlyContinue) {
    mise install
    if ($LASTEXITCODE -ne 0) { throw 'mise install failed' }

    # PowerShell profiles activate mise. cmd/Clink and editors need shims on
    # the user PATH as well; new processes pick this up without a profile.
    $miseData = if ($env:MISE_DATA_DIR) { $env:MISE_DATA_DIR }
        elseif ($env:XDG_DATA_HOME) { Join-Path $env:XDG_DATA_HOME 'mise' }
        else { Join-Path $env:LOCALAPPDATA 'mise' }
    $shims = Join-Path $miseData 'shims'
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $shims) {
        [Environment]::SetEnvironmentVariable('Path', "$shims;$userPath", 'User')
    }
}

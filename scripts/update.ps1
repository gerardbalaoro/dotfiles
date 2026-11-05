$ErrorActionPreference = 'Stop'

& git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw 'Could not update the dotfiles checkout' }
& mise exec -- fnox exec --only 'DOTFILES_*' -- mise bootstrap --update
if ($LASTEXITCODE -ne 0) { throw 'Dotfiles update failed' }

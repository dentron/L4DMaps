# Sync-L4DMapping.ps1
#
# Copies mapping files from the Git repository into the L4D/L4D2 game folder,
# preserving the repository's directory structure.
#
# The Git repository is authoritative:
# Any file in the repository will overwrite the corresponding file
# in the game directory.

[CmdletBinding()]
param(
    # Path to the root of your Git repository.
    [string]$RepoPath = $PSScriptRoot,

    # Path to the L4D/L4D2 game directory.
    [string]$GamePath = "E:\SteamLibrary\steamapps\common\Left 4 Dead 2\left4dead2",

    # Preview changes without actually copying files.
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$MappingDirectories = @(
    "campaigns",
    "materials",
    "models"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       L4D Mapping File Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Repository: $RepoPath"
Write-Host "Game path:  $GamePath"

if ($DryRun) {
    Write-Host "Mode:       DRY RUN" -ForegroundColor Yellow
}

Write-Host ""

try {
    # Resolve repository path.
    $RepoPath = (Resolve-Path $RepoPath).Path

    # Make sure the game directory exists.
    if (-not (Test-Path $GamePath)) {
        throw "Game path does not exist: $GamePath"
    }

    $GamePath = (Resolve-Path $GamePath).Path

    foreach ($Directory in $MappingDirectories) {

        $Source = Join-Path $RepoPath $Directory
        $Destination = Join-Path $GamePath $Directory

        if (-not (Test-Path $Source)) {
            Write-Host "Skipping missing directory: $Source" -ForegroundColor DarkYellow
            continue
        }

        Write-Host "Syncing: $Directory" -ForegroundColor Green

        if (-not $DryRun) {
            # Create destination directory if necessary.
            if (-not (Test-Path $Destination)) {
                New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            }
        }

        # /E      Copy all subdirectories, including empty ones
        # /FFT    Use flexible file-time comparison
        # /R:2    Retry failed copies twice
        # /W:1    Wait 1 second between retries
        # /L      List only (DryRun)
        # /NJH    No job header
        # /NJS    No job summary
        # /NP     No progress percentage
        #
        # NOTE: /XO has intentionally been removed.
        # Files from the repository ALWAYS overwrite files in the game directory.

        if ($DryRun) {
            robocopy $Source $Destination /E /FFT /R:2 /W:1 /L /NJH /NJS /NP
        }
        else {
            robocopy $Source $Destination /E /FFT /R:2 /W:1 /NJH /NJS /NP

            # Robocopy exit codes 0-7 indicate success.
            if ($LASTEXITCODE -gt 7) {
                throw "Robocopy failed while syncing '$Directory'. Exit code: $LASTEXITCODE"
            }
        }
    }

    Write-Host ""
    Write-Host "Sync complete." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

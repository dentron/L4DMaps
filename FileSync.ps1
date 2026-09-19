# Sync-L4DMapping.ps1
#
# Copies mapping files from the Git repository into the L4D/L4D2 game folder.
#
# The Git repository is authoritative:
# Any file in the repository will overwrite the corresponding file
# in the game directory.
#
# The game path is read from gamepath.txt.
#
# gamepath.txt should contain ONLY the full path to the game directory.
#
# Example:
# E:\SteamLibrary\steamapps\common\Left 4 Dead 2\left4dead2

[CmdletBinding()]
param(
    # Preview changes without actually copying files.
    [switch]$DryRun,

    # Used when GitHelper launches this script.
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"

# --------------------------------------------
# Paths
# --------------------------------------------

$RepoPath = $PSScriptRoot
$GamePathFile = Join-Path $RepoPath "gamepath.txt"

$MappingDirectories = @(
    "campaigns",
    "materials",
    "models"
)

# --------------------------------------------
# Header
# --------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       L4D Mapping File Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------
# Main
# --------------------------------------------

try {

    # ----------------------------------------
    # Validate repository
    # ----------------------------------------

    if ([string]::IsNullOrWhiteSpace($RepoPath)) {
        throw "Could not determine the repository directory."
    }

    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        throw "Repository directory does not exist: $RepoPath"
    }

    $RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

    Write-Host "Repository: $RepoPath"

    # ----------------------------------------
    # Read gamepath.txt
    # ----------------------------------------

    Write-Host "Config:     $GamePathFile"

    if (-not (Test-Path -LiteralPath $GamePathFile -PathType Leaf)) {
        throw "gamepath.txt was not found. Create it next to FileSync.ps1."
    }

    $GamePath = Get-Content -LiteralPath $GamePathFile -Raw

    if ($null -eq $GamePath) {
        throw "Could not read gamepath.txt."
    }

    $GamePath = $GamePath.Trim()

    # Remove surrounding quotes if present.
    if ($GamePath.StartsWith('"') -and $GamePath.EndsWith('"')) {
        $GamePath = $GamePath.Substring(1, $GamePath.Length - 2).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($GamePath)) {
        throw "gamepath.txt is empty."
    }

    Write-Host "Game path:  $GamePath"

    if ($DryRun) {
        Write-Host "Mode:       DRY RUN" -ForegroundColor Yellow
    }

    Write-Host ""

    # ----------------------------------------
    # Validate game directory
    # ----------------------------------------

    if (-not (Test-Path -LiteralPath $GamePath -PathType Container)) {
        throw "Game path does not exist: $GamePath"
    }

    $GamePath = (Resolve-Path -LiteralPath $GamePath).Path

    # ----------------------------------------
    # Sync directories
    # ----------------------------------------

    foreach ($Directory in $MappingDirectories) {

        $Source = Join-Path $RepoPath $Directory
        $Destination = Join-Path $GamePath $Directory

        if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
            Write-Host "Skipping missing directory: $Source" -ForegroundColor DarkYellow
            continue
        }

        Write-Host "Syncing: $Directory" -ForegroundColor Green

        if (-not $DryRun) {
            if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
                New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            }
        }

        # Repository is authoritative.
        # Files in the repository overwrite corresponding game files.
        #
        # /E      Include all subdirectories, including empty ones
        # /FFT    Flexible file-time comparison
        # /R:2    Retry twice
        # /W:1    Wait one second between retries
        # /L      List only (dry run)
        # /NJH    No job header
        # /NJS    No job summary
        # /NP     No progress percentage

        if ($DryRun) {

            robocopy `
                $Source `
                $Destination `
                /E `
                /FFT `
                /R:2 `
                /W:1 `
                /L `
                /NJH `
                /NJS `
                /NP

        }
        else {

            robocopy `
                $Source `
                $Destination `
                /E `
                /FFT `
                /R:2 `
                /W:1 `
                /NJH `
                /NJS `
                /NP

            # Robocopy exit codes 0-7 indicate success.
            if ($LASTEXITCODE -gt 7) {
                throw "Robocopy failed while syncing '$Directory'. Exit code: $LASTEXITCODE"
            }
        }
    }

    # ----------------------------------------
    # Success
    # ----------------------------------------

    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGreen
    Write-Host "           Sync complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor DarkGreen

}
catch {

    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red

    if (-not $NoPause) {
        Write-Host ""
        Read-Host "Press Enter to exit"
    }

    exit 1
}

# --------------------------------------------
# Pause when run directly
# --------------------------------------------

if (-not $NoPause) {
    Write-Host ""
    Read-Host "Press Enter to exit"
}

exit 0

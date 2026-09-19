# ============================================
# Git Helper
# Git + FileSync helper for non-command-line users
# ============================================

Set-Location $PSScriptRoot

$FileSyncScript = Join-Path $PSScriptRoot "FileSync.ps1"

function Pause-Script {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor DarkCyan
    Write-Host "              Git Helper" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "Repository: $PSScriptRoot" -ForegroundColor DarkGray
    Write-Host ""
}

function Test-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git could not be found." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please make sure Git is installed and try again."
        Pause-Script
        return $false
    }

    return $true
}

function Run-FileSync {
    Write-Host ""
    Write-Host "Running FileSync.ps1..." -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $FileSyncScript)) {
        Write-Host "FileSync.ps1 was not found." -ForegroundColor Red
        Write-Host "Expected location:" -ForegroundColor Yellow
        Write-Host $FileSyncScript
        return $false
    }

    try {
        & $FileSyncScript

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "File sync completed successfully!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host ""
            Write-Host "FileSync.ps1 reported an error." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host ""
        Write-Host "Could not run FileSync.ps1:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
}

function Pull-Changes {
    Show-Header

    Write-Host "Pulling the latest changes..." -ForegroundColor Cyan
    Write-Host ""

    git pull

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Pull completed successfully!" -ForegroundColor Green

        Run-FileSync
    }
    else {
        Write-Host ""
        Write-Host "The pull encountered a problem." -ForegroundColor Red
        Write-Host "FileSync was not run."
    }

    Pause-Script
}

function Commit-Changes {
    Show-Header

    Write-Host "Checking for changes..." -ForegroundColor Cyan
    Write-Host ""

    git status --short

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Unable to check repository status." -ForegroundColor Red
        Pause-Script
        return
    }

    Write-Host ""

    $message = Read-Host "Enter your commit message"

    if ([string]::IsNullOrWhiteSpace($message)) {
        Write-Host ""
        Write-Host "A commit message is required." -ForegroundColor Yellow
        Pause-Script
        return
    }

    Write-Host ""
    Write-Host "Adding all new, modified, and deleted files..." -ForegroundColor Cyan

    git add -A

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not add the files." -ForegroundColor Red
        Pause-Script
        return
    }

    Write-Host "Creating commit..." -ForegroundColor Cyan
    Write-Host ""

    git commit -m $message

    Write-Host ""

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Commit created successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "Nothing was committed, or the commit encountered a problem." -ForegroundColor Yellow
    }

    Pause-Script
}

function Push-Changes {
    Show-Header

    Write-Host "Pushing your commits..." -ForegroundColor Cyan
    Write-Host ""

    git push

    Write-Host ""

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Push completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "The push encountered a problem." -ForegroundColor Red
    }

    Pause-Script
}

function Sync-Repository {
    Show-Header

    Write-Host "Starting sync..." -ForegroundColor Cyan
    Write-Host ""

    # --------------------------------------------
    # Step 1: Pull
    # --------------------------------------------

    Write-Host "1/4 - Pulling latest changes..." -ForegroundColor Cyan
    Write-Host ""

    git pull

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Pull failed." -ForegroundColor Red
        Write-Host "FileSync was not run."
        Pause-Script
        return
    }

    Write-Host ""
    Write-Host "Pull completed successfully!" -ForegroundColor Green

    # --------------------------------------------
    # Step 2: File Sync
    # --------------------------------------------

    Write-Host ""
    Write-Host "2/4 - Synchronizing files..." -ForegroundColor Cyan

    $syncSuccess = Run-FileSync

    if (-not $syncSuccess) {
        Write-Host ""
        Write-Host "File synchronization encountered a problem." -ForegroundColor Yellow
    }

    # --------------------------------------------
    # Step 3: Check local changes
    # --------------------------------------------

    Write-Host ""
    Write-Host "3/4 - Checking for local changes..." -ForegroundColor Cyan
    Write-Host ""

    $status = git status --porcelain

    if ([string]::IsNullOrWhiteSpace(($status -join ""))) {
        Write-Host "There are no local changes to commit." -ForegroundColor Green
    }
    else {
        Write-Host $status
        Write-Host ""

        $message = Read-Host "Enter a commit message"

        if ([string]::IsNullOrWhiteSpace($message)) {
            Write-Host ""
            Write-Host "No commit message entered." -ForegroundColor Yellow
            Write-Host "Stopping sync before pushing."
            Pause-Script
            return
        }

        git add -A

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Could not add files." -ForegroundColor Red
            Pause-Script
            return
        }

        git commit -m $message

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "Commit failed. Stopping sync." -ForegroundColor Red
            Pause-Script
            return
        }

        Write-Host ""
        Write-Host "Commit created!" -ForegroundColor Green
    }

    # --------------------------------------------
    # Step 4: Push
    # --------------------------------------------

    Write-Host ""
    Write-Host "4/4 - Pushing changes..." -ForegroundColor Cyan
    Write-Host ""

    git push

    Write-Host ""

    if ($LASTEXITCODE -eq 0) {
        Write-Host "==========================================" -ForegroundColor DarkGreen
        Write-Host "             Sync complete!" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor DarkGreen
    }
    else {
        Write-Host "Push failed." -ForegroundColor Yellow
        Write-Host "Your changes are still committed locally."
    }

    Pause-Script
}

# ============================================
# Main Menu
# ============================================

if (-not (Test-Git)) {
    exit
}

while ($true) {
    Show-Header

    Write-Host "What would you like to do?" -ForegroundColor White
    Write-Host ""

    Write-Host "  [1] " -NoNewline -ForegroundColor Cyan
    Write-Host "Pull latest changes"

    Write-Host "  [2] " -NoNewline -ForegroundColor Cyan
    Write-Host "Commit my changes"

    Write-Host "  [3] " -NoNewline -ForegroundColor Cyan
    Write-Host "Push my commits"

    Write-Host "  [4] " -NoNewline -ForegroundColor Green
    Write-Host "Sync (Pull + FileSync + Commit + Push)"

    Write-Host "  [5] " -NoNewline -ForegroundColor Cyan
    Write-Host "Exit"

    Write-Host ""

    $choice = Read-Host "Choose an option"

    switch ($choice) {
        "1" {
            Pull-Changes
        }

        "2" {
            Commit-Changes
        }

        "3" {
            Push-Changes
        }

        "4" {
            Sync-Repository
        }

        "5" {
            Clear-Host
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit
        }

        default {
            Write-Host ""
            Write-Host "Please choose a number from 1 to 5." -ForegroundColor Yellow
            Start-Sleep -Seconds 1.5
        }
    }
}

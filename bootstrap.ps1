# bootstrap.ps1 - Windows 11 dev environment setup
# One command to transform a fresh Windows 11 machine into a fully configured dev environment
#
# Usage: irm https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.ps1 | iex
#
# Output is logged to: ~\.dotfiles-bootstrap-YYYYMMDD_HHMMSS.log
# Both console output and log file are updated simultaneously

#Requires -Version 7.0

#===============================================================================
# Global Configuration
#===============================================================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Speed up downloads

$DOTFILES_DIR = "$HOME\.dotfiles"
$GITHUB_REPO = "seanGSISG/.dotfiles"

# Detect GitHub repo from existing git remote if available
if (Test-Path "$DOTFILES_DIR\.git") {
    try {
        $remoteUrl = git -C $DOTFILES_DIR remote get-url origin 2>$null
        if ($remoteUrl -match 'github\.com[:/](.+?)(?:\.git)?$') {
            $GITHUB_REPO = $Matches[1]
        }
    } catch {}
}

#===============================================================================
# Logging Setup
#===============================================================================

$LOG_FILE = "$HOME\.dotfiles-bootstrap-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to write to both console and log file
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$Color = 'White'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $LOG_FILE -Value $logMessage
    
    # Write to console with color
    Write-Host $Message -ForegroundColor $Color
}

function Log-Info {
    param([string]$Message)
    Write-Log -Message "▶ $Message" -Level 'INFO' -Color Cyan
}

function Log-Success {
    param([string]$Message)
    Write-Log -Message "✓ $Message" -Level 'SUCCESS' -Color Green
}

function Log-Skip {
    param([string]$Message)
    Write-Log -Message "⊘ $Message (skipped)" -Level 'SKIP' -Color Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Log -Message "✗ $Message" -Level 'ERROR' -Color Red
}

function Section-Header {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
}

#===============================================================================
# Error Tracking
#===============================================================================

$script:FailedSteps = @()
$script:InstalledItems = @()
$script:SkippedItems = @()

function Invoke-Step {
    param(
        [string]$StepName,
        [scriptblock]$ScriptBlock
    )
    
    try {
        & $ScriptBlock
        return $true
    } catch {
        Log-Error "$StepName failed: $_"
        $script:FailedSteps += $StepName
        return $false
    }
}

#===============================================================================
# Prerequisites Check
#===============================================================================

function Test-Prerequisites {
    Section-Header "Checking Prerequisites"
    
    $missing = $false
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Log-Success "PowerShell $($PSVersionTable.PSVersion) available"
    } else {
        Log-Error "PowerShell 7+ required (found $($PSVersionTable.PSVersion))"
        $missing = $true
    }
    
    # Check winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log-Success "winget available"
    } else {
        Log-Error "winget not found - install from Microsoft Store or update Windows"
        $missing = $true
    }
    
    # Check git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Log-Success "git available"
    } else {
        Log-Error "git not found"
        $missing = $true
    }
    
    if ($missing) {
        throw "Missing required prerequisites. Install them and retry."
    }
    
    Log-Success "All prerequisites available"
}

#===============================================================================
# Chezmoi Installation
#===============================================================================

function Install-Chezmoi {
    Section-Header "Installing Chezmoi"
    
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        Log-Skip "chezmoi already installed"
        $script:SkippedItems += "chezmoi"
        return
    }
    
    Log-Info "Installing chezmoi via winget..."
    winget install --id twpayne.chezmoi --exact --accept-source-agreements --accept-package-agreements --silent
    
    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        Log-Success "chezmoi installed"
        $script:InstalledItems += "chezmoi"
    } else {
        throw "chezmoi installation failed"
    }
}

#===============================================================================
# Dotfiles Repository
#===============================================================================

function Initialize-DotfilesRepo {
    Section-Header "Setting Up Dotfiles Repository"
    
    if (Test-Path "$DOTFILES_DIR\.git") {
        Log-Skip "Dotfiles repository already cloned"
        $script:SkippedItems += "dotfiles clone"
        
        # Update existing repo
        Log-Info "Updating existing repository..."
        git -C $DOTFILES_DIR pull --quiet
        Log-Success "Repository updated"
        return
    }
    
    Log-Info "Cloning dotfiles repository from $GITHUB_REPO..."
    
    # Backup existing dotfiles directory if it exists but isn't a git repo
    if (Test-Path $DOTFILES_DIR) {
        $backupDir = "$HOME\.dotfiles-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Log-Info "Backing up existing $DOTFILES_DIR to $backupDir..."
        Move-Item $DOTFILES_DIR $backupDir
        Log-Success "Backup created at $backupDir"
    }
    
    git clone "https://github.com/$GITHUB_REPO.git" $DOTFILES_DIR
    Log-Success "Repository cloned to $DOTFILES_DIR"
    $script:InstalledItems += "dotfiles repository"
}

#===============================================================================
# Winget Package Installation
#===============================================================================

function Install-WingetPackages {
    Section-Header "Installing Windows Packages"
    
    $packageFile = "$DOTFILES_DIR\packages\winget-packages.txt"
    
    if (-not (Test-Path $packageFile)) {
        Log-Skip "Package list not found at $packageFile"
        return
    }
    
    Log-Info "Reading package list from $packageFile..."
    
    $packages = Get-Content $packageFile | Where-Object {
        $_.Trim() -and -not $_.TrimStart().StartsWith('#')
    }
    
    $installedCount = 0
    $skippedCount = 0
    
    foreach ($packageId in $packages) {
        $packageId = $packageId.Trim()

        # Strip inline comments (e.g., "Microsoft.PowerShell  # description" -> "Microsoft.PowerShell")
        if ($packageId -match '^([^#]+)') {
            $packageId = $Matches[1].Trim()
        }

        if (-not $packageId) { continue }

        Log-Info "Installing $packageId..."
        winget install --id $packageId --exact --accept-source-agreements --accept-package-agreements --silent

        if ($LASTEXITCODE -eq 0) {
            Log-Success "$packageId installed"
            $installedCount++
        } elseif ($LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335146) {
            # -1978335189: No applicable update (already up to date)
            # -1978335146: Package already installed
            Log-Skip "$packageId already installed"
            $skippedCount++
        } else {
            Log-Error "$packageId installation failed (exit code: $LASTEXITCODE)"
            $script:FailedSteps += "winget install $packageId"
        }
    }
    
    Log-Info "Packages installed: $installedCount, skipped: $skippedCount"
    
    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if ($installedCount -gt 0) {
        $script:InstalledItems += "$installedCount winget packages"
    }
}

#===============================================================================
# Age Key Setup
#===============================================================================

function Set-AgeKey {
    Section-Header "Age Encryption Key Setup"
    
    $ageKeyPath = "$HOME\.config\age\keys.txt"
    
    if (Test-Path $ageKeyPath) {
        Log-Skip "Age key already exists at $ageKeyPath"
        $script:SkippedItems += "age key"
        return
    }
    
    Write-Host ""
    Write-Host "Age encryption key is required to decrypt secrets." -ForegroundColor Yellow
    Write-Host "Retrieve it from Bitwarden and paste it when prompted." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to continue or Ctrl+C to skip..." -ForegroundColor Cyan
    Read-Host
    
    Write-Host "Paste your age key (it will not be displayed): " -ForegroundColor Cyan -NoNewline
    $ageKey = Read-Host -AsSecureString
    
    if ($ageKey.Length -eq 0) {
        Log-Skip "Age key setup skipped (you can add it later to $ageKeyPath)"
        $script:SkippedItems += "age key"
        return
    }
    
    # Convert SecureString to plain text for file write
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ageKey)
    $plainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    # Create directory and save key
    $ageKeyDir = Split-Path $ageKeyPath -Parent
    if (-not (Test-Path $ageKeyDir)) {
        New-Item -ItemType Directory -Path $ageKeyDir -Force | Out-Null
    }
    
    Set-Content -Path $ageKeyPath -Value $plainKey -NoNewline
    
    # Set restrictive permissions (current user only)
    $acl = Get-Acl $ageKeyPath
    $acl.SetAccessRuleProtection($true, $false)  # Remove inherited permissions
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $ageKeyPath $acl
    
    Log-Success "Age key saved to $ageKeyPath"
    $script:InstalledItems += "age encryption key"
}

#===============================================================================
# Dotfile Backup
#===============================================================================

function Backup-ExistingDotfiles {
    Section-Header "Backing Up Existing Dotfiles"
    
    # Common dotfiles to check and backup
    $filesToBackup = @(
        ".gitconfig",
        ".zshrc",
        ".bashrc",
        ".profile"
    )
    
    $dirsToBackup = @(
        ".config\powershell",
        ".config\starship.toml",
        ".ssh",
        "Documents\PowerShell"
    )
    
    $itemsToBackup = @()
    
    foreach ($file in $filesToBackup) {
        $path = "$HOME\$file"
        if ((Test-Path $path) -and -not (Test-Path "$path.backup")) {
            $itemsToBackup += $path
        }
    }
    
    foreach ($dir in $dirsToBackup) {
        $path = "$HOME\$dir"
        if ((Test-Path $path) -and -not (Test-Path "$path.backup")) {
            $itemsToBackup += $path
        }
    }
    
    if ($itemsToBackup.Count -eq 0) {
        Log-Skip "No dotfiles to backup"
        $script:SkippedItems += "dotfile backup"
        return
    }
    
    $backupDir = "$HOME\.dotfiles-backup\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Log-Info "Creating backup directory at $backupDir..."
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    foreach ($item in $itemsToBackup) {
        $relativePath = $item.Substring($HOME.Length + 1)
        $backupPath = Join-Path $backupDir $relativePath
        $backupParent = Split-Path $backupPath -Parent
        
        if ($backupParent -and -not (Test-Path $backupParent)) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        }
        
        Copy-Item -Path $item -Destination $backupPath -Recurse -Force
        Log-Info "Backed up: $relativePath"
    }
    
    Log-Success "Backed up $($itemsToBackup.Count) items to $backupDir"
    $script:InstalledItems += "dotfile backup"
}

#===============================================================================
# Chezmoi Apply
#===============================================================================

function Invoke-ChezmoiApply {
    Section-Header "Deploying Dotfiles"
    
    Log-Info "Running chezmoi init and apply..."
    
    # Initialize chezmoi with the dotfiles directory
    chezmoi init --source=$DOTFILES_DIR
    if ($LASTEXITCODE -ne 0) {
        throw "chezmoi init failed (exit code: $LASTEXITCODE)"
    }

    # Apply the dotfiles
    chezmoi apply --verbose
    if ($LASTEXITCODE -ne 0) {
        throw "chezmoi apply failed (exit code: $LASTEXITCODE)"
    }

    Log-Success "Dotfiles deployed via chezmoi"
    $script:InstalledItems += "dotfile deployment"
}

#===============================================================================
# Summary
#===============================================================================

function Show-Summary {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║                  Bootstrap Complete!                          ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if ($script:InstalledItems.Count -gt 0) {
        Write-Host "Installed:" -ForegroundColor Green
        foreach ($item in $script:InstalledItems) {
            Write-Host "  ✓ $item" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if ($script:SkippedItems.Count -gt 0) {
        Write-Host "Skipped (already configured):" -ForegroundColor Yellow
        foreach ($item in $script:SkippedItems) {
            Write-Host "  ⊘ $item" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($script:FailedSteps.Count -gt 0) {
        Write-Host "Failed:" -ForegroundColor Red
        foreach ($step in $script:FailedSteps) {
            Write-Host "  ✗ $step" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Some steps failed. Check the log file for details:" -ForegroundColor Red
        Write-Host "  $LOG_FILE" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "Post-Install Checklist:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. " -NoNewline -ForegroundColor Cyan
    Write-Host "Restart your terminal " -NoNewline -ForegroundColor White
    Write-Host "to load new configurations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. " -NoNewline -ForegroundColor Cyan
    Write-Host "Age key " -NoNewline -ForegroundColor White
    Write-Host "— If skipped, retrieve from Bitwarden, save to ~/.config/age/keys.txt" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. " -NoNewline -ForegroundColor Cyan
    Write-Host "SSH verify " -NoNewline -ForegroundColor White
    Write-Host "— Run: ssh -T git@github.com" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. " -NoNewline -ForegroundColor Cyan
    Write-Host "PowerShell Modules " -NoNewline -ForegroundColor White
    Write-Host "— Install PSFzf: Install-Module PSFzf -Scope CurrentUser" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Log file: " -NoNewline -ForegroundColor Cyan
    Write-Host "$LOG_FILE" -ForegroundColor White
    Write-Host ""
}

#===============================================================================
# Main Execution
#===============================================================================

function Main {
    # Display banner
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║           Windows 11 Dev Environment Bootstrap               ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Log-Info "Logging to: $LOG_FILE"
    Write-Host ""
    
    # Check prerequisites (will throw if failed)
    Test-Prerequisites
    
    # Run all installation steps (continue on error pattern)
    $ErrorActionPreference = 'Continue'
    
    # Phase 1: Foundation
    Invoke-Step "Chezmoi Installation" { Install-Chezmoi }
    Invoke-Step "Dotfiles Repository" { Initialize-DotfilesRepo }
    
    # Phase 2: Package installation
    Invoke-Step "Windows Packages" { Install-WingetPackages }
    
    # Phase 3: Deploy configs
    Invoke-Step "Dotfile Backup" { Backup-ExistingDotfiles }
    Invoke-Step "Age Key" { Set-AgeKey }
    Invoke-Step "Chezmoi Apply" { Invoke-ChezmoiApply }
    
    # Reset error handling
    $ErrorActionPreference = 'Stop'
    
    # Show summary
    Show-Summary
}

# Run main function
try {
    Main
} catch {
    Log-Error "Fatal error during bootstrap: $_"
    Write-Host ""
    Write-Host "Bootstrap failed. Check the log file for details:" -ForegroundColor Red
    Write-Host "  $LOG_FILE" -ForegroundColor Red
    exit 1
}

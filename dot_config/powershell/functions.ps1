# Shell Functions
# Reusable functions for PowerShell
# Equivalent of: dot_config/zsh/functions.zsh

# ============================================
# Section 1: Alias Help System
# ============================================

function alias-help {
    $aliasDir = "$HOME\.config\powershell\aliases"
    if (-not (Test-Path $aliasDir)) {
        Write-Warning "Alias directory not found: $aliasDir"
        return
    }

    $bold = "`e[1m"
    $dim = "`e[2m"
    $blue = "`e[34m"
    $yellow = "`e[33m"
    $cyan = "`e[36m"
    $magenta = "`e[35m"
    $reset = "`e[0m"

    Write-Host ""
    Write-Host " ${bold}${blue}+----------------------------------------------+${reset}"
    Write-Host " ${bold}${blue}|${reset}               ${bold}Shell Cheatsheet${reset}               ${bold}${blue}|${reset}"
    Write-Host " ${bold}${blue}+----------------------------------------------+${reset}"

    foreach ($file in Get-ChildItem "$aliasDir\aliases-*.ps1" | Sort-Object Name) {
        $category = $file.BaseName -replace '^aliases-', '' | ForEach-Object { $_.ToUpper() }
        $lines = Get-Content $file.FullName
        $count = ($lines | Where-Object { $_ -match '^\s*function\s+\w+' -or $_ -match '^\s*Set-Alias' }).Count
        $dashes = '-' * (46 - $category.Length - 2)

        Write-Host ""
        Write-Host " ${bold}${yellow}${category}${reset} ${dim}${dashes}${reset} ${dim}(${count})${reset}"

        $headerLines = 0
        $pendingSection = ""

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            # Skip first 2 comment lines (file header)
            if ($line -match '^\s*#' -and $headerLines -lt 2) {
                $headerLines++
                continue
            }

            # Sub-section comment
            if ($line -match '^\s*#\s+(.+)') {
                $pendingSection = $Matches[1]
                continue
            }

            # Match function definitions: function name { ... }
            if ($line -match '^\s*function\s+(\S+)\s*\{?\s*(.*)') {
                $name = $Matches[1]

                if ($pendingSection) {
                    Write-Host ""
                    Write-Host "   ${magenta}${pendingSection}${reset}"
                    $pendingSection = ""
                }

                # Try to find inline comment
                $comment = ""
                if ($line -match '#\s*(.+)$') {
                    $comment = $Matches[1]
                }
                Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f $name, $comment)
            }

            # Match Set-Alias definitions
            if ($line -match 'Set-Alias\s+-Name\s+(\S+)\s+-Value\s+(\S+)') {
                $name = $Matches[1]
                $value = $Matches[2]

                if ($pendingSection) {
                    Write-Host ""
                    Write-Host "   ${magenta}${pendingSection}${reset}"
                    $pendingSection = ""
                }
                Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f $name, $value)
            }
        }
    }

    Write-Host ""
    $dashes = '-' * (46 - 17)
    Write-Host " ${bold}${yellow}QUICK REFERENCE${reset} ${dim}${dashes}${reset}"
    Write-Host ""
    Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f "j <name>", "Jump to workspace (ccenter, labs, ...)")
    Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f "z <query>", "Jump to directory (zoxide)")
    Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f "Ctrl+R", "Fuzzy search history (fzf/PSReadLine)")
    Write-Host ("   ${cyan}{0,-16}${reset} ${dim}{1}${reset}" -f "Ctrl+T", "Fuzzy find files (fzf)")
    Write-Host ""
}

Set-Alias -Name '?' -Value alias-help
Set-Alias -Name halp -Value alias-help

# ============================================
# Section 2: Navigation Functions
# ============================================

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# ============================================
# Section 3: Utility Functions
# ============================================

function cheat {
    param([Parameter(Mandatory)][string]$Query)
    (Invoke-WebRequest -Uri "https://cheat.sh/$Query" -UseBasicParsing).Content
}

function reload {
    . $PROFILE
}

# ============================================
# Section 4: Azure Key Vault Functions
# ============================================

function az-secret {
    param(
        [Parameter(Position = 0)][string]$Name,
        [Parameter(Position = 1)][string]$Vault
    )
    if (-not $Vault) { $Vault = if ($env:AZ_KEYVAULT) { $env:AZ_KEYVAULT } else { "kv-idm-webapp-prod" } }
    if (-not $Name) {
        Write-Host "Usage: az-secret <secret-name> [vault-name]"
        Write-Host "Default vault: $Vault (set `$env:AZ_KEYVAULT to change)"
        return
    }
    az keyvault secret show --vault-name $Vault --name $Name --query "value" -o tsv
}

function az-secrets-list {
    param([Parameter(Position = 0)][string]$Vault)
    if (-not $Vault) { $Vault = if ($env:AZ_KEYVAULT) { $env:AZ_KEYVAULT } else { "kv-idm-webapp-prod" } }
    az keyvault secret list --vault-name $Vault -o table
}

# ============================================
# Section 5: Windows Terminal + Claude Functions
# ============================================

function cct {
    # Claude Code in new Windows Terminal tab
    $prompt = $args -join ' '
    if ($prompt) {
        # Prevent command injection via Base64 encoding:
        # 1. Use -f format operator to prevent $() expansion during string construction
        # 2. Base64 encode the entire command so it's safely passed and decoded by PowerShell
        $fullCommand = "claude --dangerously-skip-permissions '{0}'" -f $prompt
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($fullCommand)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        wt new-tab --title "Claude" -- pwsh -NoLogo -EncodedCommand $encodedCommand
    } else {
        wt new-tab --title "Claude" -- pwsh -NoLogo -Command "claude --dangerously-skip-permissions"
    }
}

function ccr {
    # Claude Code in right split pane (horizontal split)
    $prompt = $args -join ' '
    if ($prompt) {
        # Prevent command injection via Base64 encoding:
        # 1. Use -f format operator to prevent $() expansion during string construction
        # 2. Base64 encode the entire command so it's safely passed and decoded by PowerShell
        $fullCommand = "claude --dangerously-skip-permissions '{0}'" -f $prompt
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($fullCommand)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        wt split-pane -H --title "Claude" -- pwsh -NoLogo -EncodedCommand $encodedCommand
    } else {
        wt split-pane -H --title "Claude" -- pwsh -NoLogo -Command "claude --dangerously-skip-permissions"
    }
}

function ccb {
    # Claude Code in bottom split pane (vertical split)
    $prompt = $args -join ' '
    if ($prompt) {
        # Prevent command injection via Base64 encoding:
        # 1. Use -f format operator to prevent $() expansion during string construction
        # 2. Base64 encode the entire command so it's safely passed and decoded by PowerShell
        $fullCommand = "claude --dangerously-skip-permissions '{0}'" -f $prompt
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($fullCommand)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        wt split-pane -V --title "Claude" -- pwsh -NoLogo -EncodedCommand $encodedCommand
    } else {
        wt split-pane -V --title "Claude" -- pwsh -NoLogo -Command "claude --dangerously-skip-permissions"
    }
}

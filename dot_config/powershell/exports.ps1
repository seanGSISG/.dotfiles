# PowerShell environment exports
# Purpose: Core environment setup - PATH, env vars, PSReadLine history
# Equivalent of: dot_config/zsh/exports.zsh

# --- Environment Variables ---
$env:EDITOR = if ($env:EDITOR) { $env:EDITOR } else { "code" }
$env:LANG = if ($env:LANG) { $env:LANG } else { "en_US.UTF-8" }
$env:ENABLE_LSP_TOOLS = "1"
$env:BUN_INSTALL = "$HOME\.bun"
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"

# --- PATH Construction ---
# Single authoritative location - no duplication
$PathEntries = @(
    "$HOME\.local\bin"
    "$env:APPDATA\fnm"
    "$HOME\.bun\bin"
    "$HOME\.opencode\bin"
)

foreach ($entry in $PathEntries) {
    if ((Test-Path $entry) -and ($env:Path -split ';' -notcontains $entry)) {
        $env:Path = "$entry;$env:Path"
    }
}

# --- PSReadLine History Configuration ---
# Equivalent of zsh HISTSIZE/SAVEHIST/setopt settings
$PSReadLineHistoryPath = "$HOME\.local\share\powershell\PSReadLine\ConsoleHost_history.txt"
$PSReadLineHistoryDir = Split-Path $PSReadLineHistoryPath -Parent
if (-not (Test-Path $PSReadLineHistoryDir)) {
    New-Item -ItemType Directory -Path $PSReadLineHistoryDir -Force | Out-Null
}

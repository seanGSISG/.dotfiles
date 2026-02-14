# PowerShell environment exports
# Purpose: Core environment setup - PATH, env vars, PSReadLine history
# Equivalent of: dot_config/zsh/exports.zsh

# --- Environment Variables ---
$env:EDITOR = if ($env:EDITOR) { $env:EDITOR } else { "code" }
$env:LANG = if ($env:LANG) { $env:LANG } else { "en_US.UTF-8" }
$env:ENABLE_LSP_TOOLS = "1"
$env:BUN_INSTALL = "$HOME\.bun"
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
$env:BAT_THEME = "Dracula"

# --- fzf Configuration ---
# Use fd for file finding (faster, respects .gitignore)
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
    $env:FZF_CTRL_T_COMMAND = 'fd --type f --hidden --follow --exclude .git'
    $env:FZF_ALT_C_COMMAND = 'fd --type d --hidden --follow --exclude .git'
}
$env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --info=inline'

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

# Ensure PSReadLine actually uses the configured history path
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -HistorySavePath $PSReadLineHistoryPath
}

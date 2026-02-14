# Tool integrations
# Each tool is loaded only if available (graceful on fresh machines)
# Equivalent of: dot_config/zsh/tools.zsh

# --- fnm (Fast Node Manager) ---
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# --- fzf (Fuzzy Finder) ---
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # PSFzf module provides Ctrl+R (history) and Ctrl+T (file finder) integration
    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf -ErrorAction SilentlyContinue
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# --- zoxide (Smart cd) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- direnv (Auto-load .envrc per directory) ---
if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (direnv hook pwsh | Out-String) })
}

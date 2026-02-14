# PSReadLine configuration
# Purpose: Autosuggestions, syntax highlighting, completion, key bindings
# Equivalent of: dot_config/zsh/plugins.zsh + .zsh_plugins.txt
#
# PSReadLine replaces these zsh plugins:
#   zsh-autosuggestions       -> PredictionSource History
#   zsh-syntax-highlighting   -> PSReadLine Colors
#   zsh-history-substring-search -> HistorySearchBackward/Forward
#   zsh-completions           -> Built-in + TabCompleteNext

if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine

    # --- Autosuggestions (like zsh-autosuggestions) ---
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView

    # --- History Configuration (mirrors zsh HISTSIZE/dedup settings) ---
    Set-PSReadLineOption -MaximumHistoryCount 100000
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$line)
        # Don't record lines starting with space (like HIST_IGNORE_SPACE)
        return $line -notmatch '^ '
    }

    # --- Key Bindings ---
    # Arrow keys for history substring search (like zsh-history-substring-search)
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Tab completion with menu (like zsh menu select)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

    # Ctrl+d to exit (like zsh/bash)
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

    # Ctrl+w to delete word backward
    Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord

    # --- Syntax Highlighting Colors (like zsh-syntax-highlighting) ---
    Set-PSReadLineOption -Colors @{
        Command            = "`e[32m"     # Green - commands
        Parameter          = "`e[90m"     # Dark gray - parameters
        String             = "`e[33m"     # Yellow - strings
        Operator           = "`e[90m"     # Dark gray - operators
        Variable           = "`e[36m"     # Cyan - variables
        Comment            = "`e[32;2m"   # Dim green - comments
        Keyword            = "`e[35m"     # Magenta - keywords
        Number             = "`e[33m"     # Yellow - numbers
        Type               = "`e[34m"     # Blue - types
        Member             = "`e[37m"     # White - members
        InlinePrediction   = "`e[90;3m"   # Dim italic - predictions
    }

    # --- Tab Completion Settings ---
    # Disable bell sound (like zsh NOBEEP option)
    Set-PSReadLineOption -BellStyle None
}

# --- CLI Tool Completions ---
# Generated completions for tools that support them
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Invoke-Expression (gh completion -s powershell)
}
if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
    Invoke-Expression (chezmoi completion powershell)
}

# System Aliases
# System-level and tool-specific shortcuts

# Claude Code
alias cc='claude'
alias ccd='claude --dangerously-skip-permissions'

# Azure Key Vault (GSI)
alias az-login='az login --tenant 07e978d3-49bb-4f6c-948d-2908f2e20014'
alias az-login-sp='az login --service-principal --username 7002e397-91b0-419f-830f-798e09b2066e --password "$AZ_SP_CLIENT_SECRET" --tenant 07e978d3-49bb-4f6c-948d-2908f2e20014'

# Quick tmux helpers
alias tn='tmux new -s'
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

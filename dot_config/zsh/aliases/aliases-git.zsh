# Git Aliases
# Version control shortcuts

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias glog='git log --oneline -15'
alias glg='git log --graph --oneline --decorate -15'
alias gd='git diff'
alias gds='git diff --staged'
alias gst='git stash'
alias gstp='git stash pop'
alias gundo='git reset HEAD~1 --soft'
alias gwip='git add -A && git commit -m "WIP"'
alias gca='git commit --amend'
alias gcane='git commit --amend --no-edit'

# Modern git (switch/restore replace checkout for clarity)
alias gsw='git switch'
alias gswc='git switch -c'
alias grs='git restore'
alias grss='git restore --staged'
alias gcp='git cherry-pick'
alias grb='git rebase'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'

# TUI
alias lg='lazygit'

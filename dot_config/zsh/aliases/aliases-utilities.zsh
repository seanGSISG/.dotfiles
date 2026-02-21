# Utility Aliases
# General system and productivity shortcuts

# System utilities
alias ports='ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null || lsof -i -P -n | grep LISTEN'
alias path='echo $PATH | tr ":" "\n"'
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | awk "{print \$1}"'
alias weather='curl -s "wttr.in?format=3"'
alias cls='clear'
alias h='history'
alias hg='history | grep'

# Editor
alias e='${EDITOR:-code}'

# Safe file operations
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# Modern CLI replacements (conditional)
if command -v lsd &>/dev/null; then
  alias ls='lsd --icon=always'
  alias ll='lsd -l --icon=always'
  alias la='lsd -la --icon=always'
  alias tree='lsd --tree --icon=always'
elif command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
  alias tree='eza --tree --icons'
else
  alias ll='ls -lah'
  alias la='ls -A'
  alias l='ls -CF'
fi

alias t='tail -f'

command -v bat &>/dev/null && alias cat='bat'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias cat='batcat'
command -v dust &>/dev/null && alias du='dust'
command -v btop &>/dev/null && alias top='btop'
command -v nvim &>/dev/null && alias vim='nvim'

# Disk usage
alias df='df -h'

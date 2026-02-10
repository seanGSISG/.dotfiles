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

# List improvements
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias t='tail -f'

# Disk usage
alias df='df -h'
alias du='du -sh'

# Docker Aliases
# Container management shortcuts

alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dcr='docker compose restart'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dprune='docker system prune -af --volumes'

# Docker functions
dex() { docker exec -it "$1" "${2:-sh}"; }
dsh() { docker exec -it "$1" sh; }
dbash() { docker exec -it "$1" bash; }
dlog() { docker logs -f "$1"; }

# TUI
alias lzd='lazydocker'

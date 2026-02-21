# Navigation Aliases
# Quick directory navigation shortcuts

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Jump to workspace directories
j() {
  case "$1" in
    ccenter)  cd ~/command-center ;;
    labs)     cd ~/labs ;;
    projects) cd ~/projects ;;
    tmp)      cd ~/tmp ;;
    tools)    cd ~/tools ;;
    dev)      cd ~/dev 2>/dev/null || echo "~/dev not found" ;;
    models)   cd ~/models 2>/dev/null || echo "~/models not found" ;;
    github)   cd ~/dev/github 2>/dev/null || echo "~/dev/github not found" ;;
    *)
      echo "Usage: j <target>"
      echo "  ccenter   ~/command-center"
      echo "  labs      ~/labs"
      echo "  projects  ~/projects"
      echo "  tmp       ~/tmp"
      echo "  tools     ~/tools"
      echo "  dev       ~/dev"
      echo "  models    ~/models"
      echo "  github    ~/dev/github"
      return 1
      ;;
  esac
}

_j() { compadd ccenter labs projects tmp tools dev models github; }
compdef _j j

# Project launchers
prefect() {
  cd ~/projects/prefect-antig && uv sync && source .venv/bin/activate && claude --dangerously-skip-permissions
}

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
    *)
      echo "Usage: j <target>"
      echo "  ccenter   ~/command-center"
      echo "  labs      ~/labs"
      echo "  projects  ~/projects"
      echo "  tmp       ~/tmp"
      echo "  tools     ~/tools"
      return 1
      ;;
  esac
}

_j() { compadd ccenter labs projects tmp tools; }
compdef _j j

# Project launchers
prefect() {
  cd ~/projects/prefect-antig && uv sync && source .venv/bin/activate && ccd
}

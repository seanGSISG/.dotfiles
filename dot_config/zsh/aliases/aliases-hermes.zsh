# Hermes Agent (NousResearch) — runs on nerd RackNerd VPS over Tailscale.
# `herm` SSHes into nerd, lands in ~/command-center (working hub), launches
# the modern TUI, then drops into a login shell at ~/command-center on exit.
alias herm='ssh -t nerd "cd ~/command-center && hermes --tui; cd ~/command-center && exec \$SHELL -l"'

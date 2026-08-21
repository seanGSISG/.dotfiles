#!/bin/bash
# Create standard workspace directories (idempotent)
# run_once_ ensures this only runs on first chezmoi apply

dirs=(
  "$HOME/projects"
  "$HOME/labs"
  "$HOME/tools"
  "$HOME/tmp"
  "$HOME/command-center"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# ~/.ssh/config sets `ControlPath ~/.ssh/sockets/%r@%h-%p`; ssh will not create
# that directory itself, and without it every multiplexed connection warns and
# falls back to an unshared session. 0700 or ssh refuses to use it.
mkdir -p "$HOME/.ssh/sockets"
chmod 700 "$HOME/.ssh/sockets"

echo "Workspace directories created."

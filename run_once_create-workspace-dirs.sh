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

echo "Workspace directories created."

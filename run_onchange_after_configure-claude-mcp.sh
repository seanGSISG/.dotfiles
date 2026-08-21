#!/bin/bash
# Configure Claude Code MCP servers and settings via CLI
# Runs after chezmoi apply (secrets already decrypted to ~/.secrets.env)
# Idempotent: claude mcp add-json overwrites existing entries

# Skip if claude is not installed
command -v claude >/dev/null 2>&1 || { echo "Claude Code not installed, skipping MCP setup"; exit 0; }

# Source secrets
if [ -f "$HOME/.secrets.env" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.secrets.env"
else
  echo "Warning: ~/.secrets.env not found — MCP servers requiring API keys may not work"
fi

# --- MCP Servers ---

# HTTP servers (no local process needed)
claude mcp add-json --scope user context7 \
  "{\"type\":\"http\",\"url\":\"https://mcp.context7.com/mcp\",\"headers\":{\"CONTEXT7_API_KEY\":\"$CONTEXT7_API_KEY\"}}"

claude mcp add-json --scope user zread \
  "{\"type\":\"http\",\"url\":\"https://api.z.ai/api/mcp/zread/mcp\",\"headers\":{\"Authorization\":\"Bearer $ZREAD_API_KEY\"}}"

claude mcp add-json --scope user grep \
  '{"type":"http","url":"https://mcp.grep.app"}'

# Stdio servers
claude mcp add-json --scope user exa_websearch \
  "{\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"-y\",\"exa-mcp-server\"],\"env\":{\"EXA_API_KEY\":\"$EXA_API_KEY\"}}"

# Disabled by default (enable per-project as needed)
claude mcp add-json --scope user codex \
  '{"type":"stdio","command":"codex","args":["-m","gpt-5.2-codex","-c","model_reasoning_effort=high","mcp-server"],"env":{},"disabled":true}'

claude mcp add-json --scope user Lokka \
  "{\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"-y\",\"@merill/lokka\"],\"env\":{\"CLIENT_ID\":\"$LOKKA_CLIENT_ID\",\"CLIENT_SECRET\":\"$LOKKA_CLIENT_SECRET\",\"TENANT_ID\":\"$LOKKA_TENANT_ID\"},\"disabled\":true}"

# DGX Spark: Additional MCP servers
if [ -f /etc/dgx-release ]; then
  if [ -n "${HF_TOKEN:-}" ]; then
    claude mcp add-json --scope user hf-mcp-server \
      "{\"type\":\"http\",\"url\":\"https://huggingface.co/mcp?login&bouquet=hf_api&mix=spaces&no_image_content=true\",\"headers\":{\"Authorization\":\"Bearer $HF_TOKEN\"}}"
  fi
fi

# --- Global Settings (disabled servers) ---
# claude mcp add-json strips the "disabled" field, so we set it via python
python3 << 'PYEOF'
import json, os

# --- Disable MCP servers ---
claude_json = os.path.expanduser("~/.claude.json")
if os.path.exists(claude_json):
    with open(claude_json, "r") as f:
        data = json.load(f)
    for name in ("codex", "Lokka"):
        if name in data.get("mcpServers", {}):
            data["mcpServers"][name]["disabled"] = True
    with open(claude_json, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Disabled MCP servers: codex, Lokka")

# --- Hooks are deliberately NOT managed here ---
# This script used to do `settings["hooks"] = {...}`, a wholesale replacement.
# That silently deleted every hook installed by GSD, context-mode, honcho, and
# herdr — 20 hook groups across 7 events — and because this is run_onchange_,
# it did so again on every edit to this file. Those installers own the hooks and
# write settings.json themselves. If you need a hook here, merge one key; never
# reassign settings["hooks"].
PYEOF

echo "Claude Code MCP servers configured."

#!/bin/bash
# Configure Claude Code MCP servers via CLI
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

# HTTP servers
claude mcp add-json --scope user context7 \
  "{\"type\":\"http\",\"url\":\"https://mcp.context7.com/mcp\",\"headers\":{\"CONTEXT7_API_KEY\":\"$CONTEXT7_API_KEY\"}}"

claude mcp add-json --scope user zread \
  "{\"type\":\"http\",\"url\":\"https://api.z.ai/api/mcp/zread/mcp\",\"headers\":{\"Authorization\":\"Bearer $ZREAD_API_KEY\"}}"

# Stdio servers
claude mcp add-json --scope user codex \
  '{"type":"stdio","command":"codex","args":["-m","gpt-5.2-codex","-c","model_reasoning_effort=high","mcp-server"],"env":{}}'

claude mcp add-json --scope user exa_websearch \
  "{\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"-y\",\"exa-mcp-server\"],\"env\":{\"EXA_API_KEY\":\"$EXA_API_KEY\"}}"

claude mcp add-json --scope user Lokka \
  "{\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"-y\",\"@merill/lokka\"],\"env\":{\"CLIENT_ID\":\"$LOKKA_CLIENT_ID\",\"CLIENT_SECRET\":\"$LOKKA_CLIENT_SECRET\",\"TENANT_ID\":\"$LOKKA_TENANT_ID\"}}"

echo "Claude Code MCP servers configured."

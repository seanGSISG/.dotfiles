#!/bin/bash
# Continuous Learning v2 - Observation Hook
#
# Captures tool use events for pattern analysis.
# Claude Code passes hook data via stdin as JSON.
#
# Hook config (in ~/.claude/settings.json):
#
# If installed as a plugin, use ${CLAUDE_PLUGIN_ROOT}:
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/hooks/observe.sh pre" }]
#     }],
#     "PostToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/hooks/observe.sh post" }]
#     }]
#   }
# }
#
# If installed manually to ~/.claude/skills:
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh pre" }]
#     }],
#     "PostToolUse": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh post" }]
#     }]
#   }
# }

set -e

CONFIG_DIR="${HOME}/.claude/insights"
OBSERVATIONS_FILE="${CONFIG_DIR}/observations.jsonl"
MAX_FILE_SIZE_MB=10

# Ensure directory exists
mkdir -p "$CONFIG_DIR"

# Skip if disabled
if [ -f "$CONFIG_DIR/disabled" ]; then
  exit 0
fi

# Read JSON from stdin (Claude Code hook format)
INPUT_JSON=$(cat)

# Exit if no input
if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# Archive if file too large
if [ -f "$OBSERVATIONS_FILE" ]; then
  file_size_mb=$(du -m "$OBSERVATIONS_FILE" 2>/dev/null | cut -f1)
  if [ "${file_size_mb:-0}" -ge "$MAX_FILE_SIZE_MB" ]; then
    archive_dir="${CONFIG_DIR}/observations.archive"
    mkdir -p "$archive_dir"
    mv "$OBSERVATIONS_FILE" "$archive_dir/observations-$(date +%Y%m%d-%H%M%S).jsonl"
  fi
fi

# Parse, build observation, and write — all in one Python call via stdin
# (piping avoids embedding JSON in bash strings which breaks on single quotes)
echo "$INPUT_JSON" | python3 -c '
import json, sys
from datetime import datetime, timezone

obs_file = sys.argv[1]

try:
    data = json.loads(sys.stdin.read())

    # Extract fields — Claude Code hook format
    # hook_event_name is the correct field; fall back to hook_type for compat
    hook_type = data.get("hook_event_name", data.get("hook_type", "unknown"))
    tool_name = data.get("tool_name", data.get("tool", "unknown"))
    tool_input = data.get("tool_input", data.get("input", {}))
    # tool_response is the correct field; fall back to tool_output for compat
    tool_output = data.get("tool_response", data.get("tool_output", ""))
    session_id = data.get("session_id", "unknown")

    # Truncate large inputs/outputs
    if isinstance(tool_input, dict):
        tool_input_str = json.dumps(tool_input)[:5000]
    else:
        tool_input_str = str(tool_input)[:5000]

    if isinstance(tool_output, dict):
        tool_output_str = json.dumps(tool_output)[:5000]
    else:
        tool_output_str = str(tool_output)[:5000]

    # Determine event type
    event = "tool_start" if "Pre" in hook_type else "tool_complete"

    observation = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "event": event,
        "tool": tool_name,
        "session": session_id,
    }

    if event == "tool_start":
        observation["input"] = tool_input_str
    else:
        observation["output"] = tool_output_str

    with open(obs_file, "a") as f:
        f.write(json.dumps(observation) + "\n")

except Exception as e:
    # Fallback: log parse error (stdin already consumed, so just log the error)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(obs_file, "a") as f:
        f.write(json.dumps({"timestamp": ts, "event": "parse_error", "error": str(e)}) + "\n")
' "$OBSERVATIONS_FILE"

# Signal observer if running
OBSERVER_PID_FILE="${CONFIG_DIR}/.observer.pid"
if [ -f "$OBSERVER_PID_FILE" ]; then
  observer_pid=$(cat "$OBSERVER_PID_FILE")
  if kill -0 "$observer_pid" 2>/dev/null; then
    kill -USR1 "$observer_pid" 2>/dev/null || true
  fi
fi

exit 0

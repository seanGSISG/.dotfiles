# DGX Spark Aliases
# Model serving, GPU monitoring, and infrastructure management

# --- [DEPRECATED] Old systemd aliases (AWQ stack removed Phase 1) ---
# Uncomment if systemd services are restored
# alias llm-status='systemctl status llama-* vllm-* sglang-* 2>/dev/null | grep -E "(●|○|\.service)"'
# alias llm-list='systemctl list-units --type=service --state=running | grep -E "(llama|vllm|sglang)"'
# alias llm-stop-all='sudo systemctl stop llama-nemotron llama-qwen3-vl vllm-glm47flash vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl 2>/dev/null'

# --- [DEPRECATED] vLLM GLM-4.7-Flash systemd aliases (AWQ stack removed Phase 1) ---
# Uncomment if systemd services are restored
# alias vllm-glm='sudo systemctl start vllm-glm47flash'
# alias vllm-glm-stop='sudo systemctl stop vllm-glm47flash'
# alias vllm-glm-logs='journalctl -u vllm-glm47flash -f'
# alias vllm-glm-status='systemctl status vllm-glm47flash'

# --- llama.cpp Nemotron ---
alias llama-nem='sudo systemctl start llama-nemotron'
alias llama-nem-stop='sudo systemctl stop llama-nemotron'
alias llama-nem-logs='journalctl -u llama-nemotron -f'

# --- llama.cpp Qwen3-VL ---
alias llama-qwen='sudo systemctl start llama-qwen3-vl'
alias llama-qwen-stop='sudo systemctl stop llama-qwen3-vl'
alias llama-qwen-logs='journalctl -u llama-qwen3-vl -f'

# --- [DEPRECATED] Quick API Tests (old AWQ endpoints) ---
# Uncomment if AWQ stack is restored
# alias test-glm='curl -s http://localhost:8000/v1/models | jq'
# alias test-nem='curl -s http://localhost:8082/health'

# --- NVFP4 Container Management (Docker) ---
# vllm-start: launch NVFP4 container (baseline or MTP) and wait for server readiness
# Usage: vllm-start        # baseline mode (chunked prefill, no speculative decoding)
#        vllm-start --mtp  # MTP speculative decoding (production config, 58-70 tok/s)
function vllm-start() {
  local mode="${1:-}"
  local repo_dir="${HOME}/labs/dgx-vllm"
  local port=8000
  local max_wait=900   # 15 minutes max (model load is 8-12 min)
  local poll_interval=10

  echo "Starting NVFP4 container${mode:+ (${mode} mode)}..."
  "${repo_dir}/run-nvfp4.sh" ${mode}

  echo "Polling /health every ${poll_interval}s (timeout: ${max_wait}s)..."
  local elapsed=0
  while [ $elapsed -lt $max_wait ]; do
    if curl -sf "http://localhost:${port}/health" >/dev/null 2>&1; then
      echo "Server ready after ${elapsed}s"
      curl -s "http://localhost:${port}/v1/models" \
        | python3 -c "import json,sys; d=json.loads(sys.stdin.read(),strict=False); print('Serving:', d['data'][0]['id'])" 2>/dev/null || true
      return 0
    fi
    sleep $poll_interval
    elapsed=$((elapsed + poll_interval))
    printf "  Loading... %ds elapsed\r" $elapsed
  done
  echo ""
  echo "ERROR: Server not ready after ${max_wait}s"
  echo "Check logs: docker logs -f vllm-nvfp4"
  return 1
}

alias vllm-stop='docker stop vllm-nvfp4 2>/dev/null; docker rm vllm-nvfp4 2>/dev/null; echo "Stopped and removed vllm-nvfp4"'   # stop + remove NVFP4 container
alias vllm-logs='docker logs -f vllm-nvfp4'                                                                                       # follow container logs
alias vllm-status='docker ps -a --filter name=vllm-nvfp4 --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'                    # container status
alias vllm-restart='vllm-stop && vllm-start'                                                                                       # stop + restart baseline mode
alias vllm-test='curl -s http://localhost:8000/v1/models | python3 -c "import json,sys; d=json.loads(sys.stdin.read(),strict=False); print(d[\"data\"][0][\"id\"])" 2>/dev/null || echo "offline"'  # quick model check

# --- Model Management ---
alias hf-download='uvx huggingface-cli download'
alias models-size='du -sh ~/models/gguf/* ~/.cache/huggingface/hub/models--* 2>/dev/null'

# --- GPU/Memory Monitoring ---
alias gpu='nvidia-smi'
alias gpuw='watch -n 1 nvidia-smi'
alias mem='free -h'

# --- System Updates ---
alias update='sudo apt update && sudo apt upgrade -y'
alias uca='pip install --upgrade claude-code anthropic openai'

# --- [DEPRECATED] Model Stack Management (Multi-Model Mode, AWQ era) ---
# Uncomment if systemd services are restored
# alias stack-start='sudo systemctl start vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl'
# alias stack-stop='sudo systemctl stop vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl'
# alias stack-status='systemctl status vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl 2>/dev/null | grep -E "(●|○|Active:)"'

# GLM multi-model mode
# alias vllm-glm-multi='sudo systemctl start vllm-glm47flash-multi'
# alias vllm-glm-multi-stop='sudo systemctl stop vllm-glm47flash-multi'
# alias vllm-glm-multi-logs='journalctl -u vllm-glm47flash-multi -f'

# Qwen3-Coder (research/agentic)
# alias vllm-coder='sudo systemctl start vllm-qwen3-coder'
# alias vllm-coder-stop='sudo systemctl stop vllm-qwen3-coder'
# alias vllm-coder-logs='journalctl -u vllm-qwen3-coder -f'

# Step3-VL (vision)
# alias vllm-vision='sudo systemctl start vllm-step3-vl'
# alias vllm-vision-stop='sudo systemctl stop vllm-step3-vl'
# alias vllm-vision-logs='journalctl -u vllm-step3-vl -f'

# Test all stack endpoints
# alias test-coder='curl -s http://localhost:8001/v1/models | jq'
# alias test-vision='curl -s http://localhost:8002/v1/models | jq'
# alias test-stack='echo "GLM (8000):"; curl -s http://localhost:8000/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"; echo "Coder (8001):"; curl -s http://localhost:8001/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"; echo "Vision (8002):"; curl -s http://localhost:8002/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"'

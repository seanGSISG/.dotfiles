# DGX Spark Aliases
# Model serving, GPU monitoring, and infrastructure management

# --- Service Overview ---
alias llm-status='systemctl status llama-* vllm-* sglang-* 2>/dev/null | grep -E "(●|○|\.service)"'
alias llm-list='systemctl list-units --type=service --state=running | grep -E "(llama|vllm|sglang)"'
alias llm-stop-all='sudo systemctl stop llama-nemotron llama-qwen3-vl vllm-glm47flash vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl 2>/dev/null'

# --- vLLM GLM-4.7-Flash ---
alias vllm-glm='sudo systemctl start vllm-glm47flash'
alias vllm-glm-stop='sudo systemctl stop vllm-glm47flash'
alias vllm-glm-logs='journalctl -u vllm-glm47flash -f'
alias vllm-glm-status='systemctl status vllm-glm47flash'

# --- llama.cpp Nemotron ---
alias llama-nem='sudo systemctl start llama-nemotron'
alias llama-nem-stop='sudo systemctl stop llama-nemotron'
alias llama-nem-logs='journalctl -u llama-nemotron -f'

# --- llama.cpp Qwen3-VL ---
alias llama-qwen='sudo systemctl start llama-qwen3-vl'
alias llama-qwen-stop='sudo systemctl stop llama-qwen3-vl'
alias llama-qwen-logs='journalctl -u llama-qwen3-vl -f'

# --- Quick API Tests ---
alias test-glm='curl -s http://localhost:8000/v1/models | jq'
alias test-nem='curl -s http://localhost:8082/health'

# --- Model Management ---
alias hf-download='HF_HOME=/home/adminuser/models/hf uvx hf download'
alias models-size='du -sh ~/models/gguf/* ~/models/hf/hub/models--* 2>/dev/null'

# --- GPU/Memory Monitoring ---
alias gpu='nvidia-smi'
alias gpuw='watch -n 1 nvidia-smi'
alias mem='free -h'

# --- System Updates ---
alias update='sudo apt update && sudo apt upgrade -y'
alias uca='pip install --upgrade claude-code anthropic openai'

# --- Model Stack Management (Multi-Model Mode) ---
alias stack-start='sudo systemctl start vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl'
alias stack-stop='sudo systemctl stop vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl'
alias stack-status='systemctl status vllm-glm47flash-multi vllm-qwen3-coder vllm-step3-vl 2>/dev/null | grep -E "(●|○|Active:)"'

# GLM multi-model mode
alias vllm-glm-multi='sudo systemctl start vllm-glm47flash-multi'
alias vllm-glm-multi-stop='sudo systemctl stop vllm-glm47flash-multi'
alias vllm-glm-multi-logs='journalctl -u vllm-glm47flash-multi -f'

# Qwen3-Coder (research/agentic)
alias vllm-coder='sudo systemctl start vllm-qwen3-coder'
alias vllm-coder-stop='sudo systemctl stop vllm-qwen3-coder'
alias vllm-coder-logs='journalctl -u vllm-qwen3-coder -f'

# Step3-VL (vision)
alias vllm-vision='sudo systemctl start vllm-step3-vl'
alias vllm-vision-stop='sudo systemctl stop vllm-step3-vl'
alias vllm-vision-logs='journalctl -u vllm-step3-vl -f'

# Test all stack endpoints
alias test-coder='curl -s http://localhost:8001/v1/models | jq'
alias test-vision='curl -s http://localhost:8002/v1/models | jq'
alias test-stack='echo "GLM (8000):"; curl -s http://localhost:8000/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"; echo "Coder (8001):"; curl -s http://localhost:8001/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"; echo "Vision (8002):"; curl -s http://localhost:8002/v1/models 2>/dev/null | jq -r ".data[0].id" || echo "offline"'

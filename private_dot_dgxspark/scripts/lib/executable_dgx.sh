#!/usr/bin/env bash
# ============================================================
# DGX-Spark-Autoconfig - DGX-Specific Utilities
# ============================================================
# Provides detection and setup functions for NVIDIA DGX Spark systems

set -euo pipefail

# Source logging if available (use local variable to avoid clobbering parent's SCRIPT_DIR)
_DGX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$_DGX_SCRIPT_DIR/logging.sh" ]] && source "$_DGX_SCRIPT_DIR/logging.sh"

# Fallback logging if not available
if ! declare -f log_info &>/dev/null; then
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_detail() { echo "  $*"; }
fi

# ============================================================
# DGX Spark Detection
# ============================================================

# Check if running on DGX Spark (Blackwell GB10)
is_dgx_spark() {
    # Check for Blackwell GB10 GPU
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | grep -q "GB10"
        return $?
    fi
    return 1
}

# Check if running on ARM64 architecture
is_arm64() {
    [[ "$(uname -m)" == "aarch64" ]]
}

# Check for NVIDIA GPU (any)
has_nvidia_gpu() {
    command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null
}

# ============================================================
# CUDA Detection & Setup
# ============================================================

# Check CUDA installation
check_cuda() {
    if [[ -d "/usr/local/cuda" ]]; then
        local cuda_version
        cuda_version=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -d',' -f1)
        log_detail "CUDA version: ${cuda_version:-unknown}"
        return 0
    fi
    log_warn "CUDA not found at /usr/local/cuda"
    return 1
}

# Get CUDA version
get_cuda_version() {
    if command -v nvcc &>/dev/null; then
        nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -d',' -f1
    elif [[ -x "/usr/local/cuda/bin/nvcc" ]]; then
        /usr/local/cuda/bin/nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -d',' -f1
    else
        echo "not found"
    fi
}

# Setup CUDA environment paths
setup_cuda_paths() {
    export PATH="/usr/local/cuda/bin:$PATH"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
    export CUDA_HOME="/usr/local/cuda"
}

# ============================================================
# GPU Information
# ============================================================

# Get GPU name
get_gpu_name() {
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1
}

# Get GPU memory info
get_gpu_memory() {
    nvidia-smi --query-gpu=memory.total,memory.used,memory.free --format=csv,noheader 2>/dev/null
}

# Get GPU driver version
get_driver_version() {
    nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1
}

# Check available unified memory (for LLM workloads)
check_unified_memory() {
    local total_mem
    total_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1 | tr -d ' ')
    log_detail "GPU Memory: $total_mem"
}

# ============================================================
# System Checks
# ============================================================

# Run all DGX preflight checks
dgx_preflight() {
    local all_pass=true

    log_info "Running DGX Spark preflight checks..."

    # 1. Check architecture
    if is_arm64; then
        log_success "Architecture: ARM64 (aarch64)"
    else
        log_warn "Not ARM64 architecture - may not be DGX Spark"
        all_pass=false
    fi

    # 2. Check for NVIDIA GPU
    if has_nvidia_gpu; then
        local gpu_name
        gpu_name=$(get_gpu_name)
        log_success "NVIDIA GPU detected: $gpu_name"
    else
        log_error "nvidia-smi not found or no GPU detected"
        all_pass=false
    fi

    # 3. Check for GB10 GPU specifically
    if is_dgx_spark; then
        log_success "DGX Spark GB10 GPU confirmed"
    else
        log_warn "Not a GB10 GPU - this installer is optimized for DGX Spark"
    fi

    # 4. Check CUDA
    if check_cuda; then
        log_success "CUDA found: $(get_cuda_version)"
    else
        log_error "CUDA not found"
        all_pass=false
    fi

    # 5. Check Docker (should be present)
    if command -v docker &>/dev/null; then
        log_success "Docker available: $(docker --version | awk '{print $3}' | tr -d ',')"
    else
        log_warn "Docker not found"
    fi

    # 6. Check disk space
    local available_space
    available_space=$(df -BG /home 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ -n "$available_space" ]] && [[ "$available_space" -ge 10 ]]; then
        log_success "Disk space: ${available_space}GB available"
    else
        log_warn "Low disk space: ${available_space:-unknown}GB available (recommend 10GB+)"
    fi

    if [[ "$all_pass" == "true" ]]; then
        log_success "All preflight checks passed"
        return 0
    else
        log_warn "Some preflight checks failed - installation may have issues"
        return 1
    fi
}

# ============================================================
# DGX-Specific Environment Setup
# ============================================================

# Set optimal environment variables for DGX Spark
setup_dgx_env() {
    # CUDA paths
    setup_cuda_paths

    # Blackwell-specific settings for vLLM/inference
    export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-12.1a}"

    # Memory settings for large models
    export PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-expandable_segments:True}"
}

# Print DGX system info
dgx_info() {
    echo "=== DGX Spark System Information ==="
    echo ""
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Architecture: $(uname -m)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "=== GPU ==="
    echo "Name: $(get_gpu_name)"
    echo "Driver: $(get_driver_version)"
    echo "Memory: $(get_gpu_memory)"
    echo ""
    echo "=== CUDA ==="
    echo "Version: $(get_cuda_version)"
    echo "Path: ${CUDA_HOME:-/usr/local/cuda}"
    echo ""
    echo "=== Disk ==="
    df -h /home 2>/dev/null | tail -1
}

# ============================================================
# Main (if run directly)
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-info}" in
        preflight|check)
            dgx_preflight
            ;;
        info|status)
            dgx_info
            ;;
        *)
            echo "Usage: $0 {preflight|info}"
            echo ""
            echo "Commands:"
            echo "  preflight  Run DGX Spark preflight checks"
            echo "  info       Display DGX system information"
            ;;
    esac
fi

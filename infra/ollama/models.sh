#!/bin/bash
# Download required Llama models for private AI system

set -euo pipefail

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

echo "=== Ollama Model Setup ==="
echo "Ollama host: $OLLAMA_HOST"
echo ""

# Required models (Llama family only)
MODELS=(
    "llama3.3:latest"      # General purpose (default)
    "llama3.2:latest"      # Fallback (smaller)
    "codellama:34b"        # Coding tasks
    # "llama3.3:70b"       # Heavy reasoning (uncomment if enough RAM)
)

for model in "${MODELS[@]}"; do
    echo ">>> Pulling $model ..."
    ollama pull "$model"
    echo ""
done

echo "=== Installed Models ==="
ollama list

echo ""
echo "=== Memory Usage Guide ==="
echo "| Model           | VRAM/RAM Required |"
echo "|-----------------|-------------------|"
echo "| llama3.3        | ~8GB              |"
echo "| llama3.2        | ~4GB              |"
echo "| codellama:34b   | ~20GB             |"
echo "| llama3.3:70b    | ~40GB (Q4)        |"
echo ""
echo "Done!"

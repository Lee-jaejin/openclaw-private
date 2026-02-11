#!/bin/bash
# Download required Llama models for private AI system

set -euo pipefail

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

echo "=== Ollama Model Setup ==="
echo "Ollama host: $OLLAMA_HOST"
echo ""

# Required models
MODELS=(
    "gpt-oss:20b"          # General purpose (default)
    "starcoder2:15b"       # Coding tasks
    "phi4:14b"             # Reasoning tasks
    "llama3.2:latest"      # Fallback (smaller)
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
echo "| gpt-oss:20b     | ~12GB             |"
echo "| starcoder2:15b  | ~9GB              |"
echo "| phi4:14b        | ~9GB              |"
echo "| llama3.2        | ~4GB              |"
echo ""
echo "Done!"

---
id: ollama-setup
title: Ollama Setup
sidebar_position: 6
---

# Ollama Setup

Local LLM inference engine configuration.

## Installation

### macOS

```bash
brew install ollama
```

### Linux

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Docker

```bash
cd infra/ollama
docker-compose up -d
```

## Model Downloads

```bash
# CodeLlama for coding tasks
ollama pull codellama:34b

# Llama 3.3 for general and reasoning
ollama pull llama3.3:latest

# Optional: Lighter model for limited RAM
ollama pull codellama:13b
ollama pull llama3.2:latest
```

## Configuration

### Bind to Localhost Only (Recommended)

```bash
# Default - localhost only
ollama serve
```

### Allow Network Access (VPN Internal)

```bash
# For VPN internal access
OLLAMA_HOST=0.0.0.0 ollama serve
```

### Environment Variables

```bash
# ~/.zshrc or ~/.bashrc
export OLLAMA_HOST=127.0.0.1
export OLLAMA_MODELS=~/.ollama/models
export OLLAMA_KEEP_ALIVE=5m
```

## Memory Requirements

| Model | RAM Required | Quantization |
|-------|-------------|--------------|
| CodeLlama 34B | 20GB+ | Q4_K_M |
| Llama 3.3 70B | 40GB+ | Q4_K_M |
| Llama 3.3 8B | 6GB+ | Q4_K_M |
| CodeLlama 13B | 10GB+ | Q4_K_M |

## API Usage

### Check Available Models

```bash
curl http://localhost:11434/api/tags
```

### Generate Response

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.3",
  "prompt": "Hello, how are you?"
}'
```

### Chat API

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "codellama:34b",
  "messages": [
    {"role": "user", "content": "Write a Python function to sort a list"}
  ]
}'
```

## Troubleshooting

### Model Not Loading

```bash
# Check running models
curl http://localhost:11434/api/ps

# Check disk space
df -h ~/.ollama

# Remove and re-download
ollama rm codellama:34b
ollama pull codellama:34b
```

### Out of Memory

```bash
# Use smaller quantization
ollama pull codellama:34b-q4_0

# Or use smaller model
ollama pull codellama:13b
```

### Slow Inference

- Ensure GPU acceleration is enabled
- Check `Activity Monitor` for memory pressure
- Consider using quantized models

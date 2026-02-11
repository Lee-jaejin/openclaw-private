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

### Podman

```bash
cd infra/ollama
podman compose up -d
```

### Podman with NVIDIA GPU

```bash
cd infra/ollama
podman compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## Model Downloads

Use the provided script to download all configured models:

```bash
bash infra/ollama/models.sh
```

Or pull models individually:

```bash
ollama pull <model-name>

# Check installed models
ollama list
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

See `infra/ollama/models.sh` for the current model list and RAM requirements. General guideline:

| Model Size | RAM Required | Quantization |
|------------|-------------|--------------|
| ~7B | 4-6GB | Q4_K_M |
| ~14B | 8-10GB | Q4_K_M |
| ~20B | 12-14GB | Q4_K_M |
| ~34B | 20GB+ | Q4_K_M |
| ~70B | 40GB+ | Q4_K_M |

## API Usage

### Check Available Models

```bash
curl http://localhost:11434/api/tags
```

### Generate Response

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "<model-name>",
  "prompt": "Hello, how are you?"
}'
```

### Chat API

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "<model-name>",
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
ollama rm <model-name>
ollama pull <model-name>
```

### Out of Memory

```bash
# Use smaller quantization
ollama pull <model-name>-q4_0

# Or switch to a smaller model in config/openclaw.json
```

### Slow Inference

- Ensure GPU acceleration is enabled
- Check `Activity Monitor` for memory pressure
- Consider using quantized models

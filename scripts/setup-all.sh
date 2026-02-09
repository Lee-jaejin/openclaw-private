#!/bin/bash
# Complete setup script for Private AI System
# Installs and configures: Headscale, Tailscale, Ollama, OpenClaw

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "   Private AI System - Complete Setup"
echo "============================================"
echo ""
echo "This script will set up:"
echo "  1. Headscale (coordination server)"
echo "  2. Tailscale (mesh network client)"
echo "  3. Ollama (local LLM server)"
echo "  4. OpenClaw (AI assistant)"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "=== Step 1: Headscale ==="
cd "$PROJECT_DIR/infra/headscale"
if command -v docker &> /dev/null; then
    echo "Starting Headscale container..."
    docker compose up -d
    echo "Headscale started on port 8080"
else
    echo "Docker not found. Please install Docker first."
    echo "  brew install --cask docker  # macOS"
    echo "  curl -fsSL https://get.docker.com | sh  # Linux"
fi

echo ""
echo "=== Step 2: Tailscale ==="
bash "$PROJECT_DIR/infra/tailscale/install.sh"

echo ""
echo "=== Step 3: Ollama ==="
if command -v ollama &> /dev/null; then
    echo "Ollama already installed."
else
    echo "Installing Ollama..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install ollama
    else
        curl -fsSL https://ollama.com/install.sh | sh
    fi
fi

echo "Starting Ollama..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew services start ollama 2>/dev/null || ollama serve &
else
    systemctl --user start ollama 2>/dev/null || ollama serve &
fi
sleep 3

echo "Downloading models..."
bash "$PROJECT_DIR/infra/ollama/models.sh"

echo ""
echo "=== Step 4: OpenClaw ==="
if command -v openclaw &> /dev/null; then
    echo "OpenClaw already installed."
else
    echo "Installing OpenClaw..."
    npm install -g openclaw
fi

echo ""
echo "Applying OpenClaw configuration..."
OPENCLAW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/openclaw"
mkdir -p "$OPENCLAW_CONFIG_DIR"
cp "$PROJECT_DIR/config/openclaw.json" "$OPENCLAW_CONFIG_DIR/config.json"
echo "Configuration copied to $OPENCLAW_CONFIG_DIR/config.json"

echo ""
echo "============================================"
echo "   Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Connect Tailscale to Headscale:"
echo "     tailscale up --login-server=https://headscale.local:8080"
echo ""
echo "  2. Register node on Headscale server:"
echo "     docker exec headscale headscale users create <username>"
echo "     docker exec headscale headscale nodes register --user <username> --key <nodekey>"
echo ""
echo "  3. Run health check:"
echo "     bash $SCRIPT_DIR/health-check.sh"
echo ""
echo "  4. Start OpenClaw:"
echo "     openclaw"
echo ""

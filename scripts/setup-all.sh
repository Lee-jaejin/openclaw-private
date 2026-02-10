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

HAS_PODMAN=false
if command -v podman &> /dev/null; then
    HAS_PODMAN=true
fi

echo ""
echo "=== Step 1: Headscale ==="
if [[ "$HAS_PODMAN" == true ]]; then
    cd "$PROJECT_DIR/infra/headscale"
    echo "Starting Headscale container..."
    podman compose up -d
    echo "Headscale started on port 8080"
else
    echo "[SKIP] Podman not found. Headscale requires Podman."
    echo "  brew install podman  # macOS"
    echo "  sudo dnf install podman  # Fedora/RHEL"
    echo "  sudo apt install podman  # Debian/Ubuntu"
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
echo "=== Step 4: OpenClaw (Container) ==="
if [[ "$HAS_PODMAN" != true ]]; then
    echo "[SKIP] Podman not found. OpenClaw container requires Podman."
elif podman ps --format '{{.Names}}' | grep -q "^openclaw$"; then
    echo "OpenClaw container already running."
else
    echo "Building OpenClaw container..."
    if podman compose build; then
        echo "Starting OpenClaw container..."
        podman compose up -d
        echo "OpenClaw started on port 18789"
    else
        echo ""
        echo "  [WARN] OpenClaw container build failed."
        echo "  The 'openclaw' npm package may not be available yet."
        echo "  Once available, build and start manually:"
        echo "    cd $PROJECT_DIR/infra/openclaw && podman compose up -d --build"
        echo ""
    fi
fi

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
echo "     podman exec headscale headscale users create <username>"
echo "     podman exec headscale headscale nodes register --user <username> --key <nodekey>"
echo ""
echo "  3. Run health check:"
echo "     bash $SCRIPT_DIR/health-check.sh"
echo ""

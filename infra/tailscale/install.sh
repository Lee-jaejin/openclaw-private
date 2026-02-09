#!/bin/bash
# Tailscale client installation and configuration for private Headscale network

set -euo pipefail

HEADSCALE_URL="${HEADSCALE_URL:-https://headscale.local:8080}"

echo "=== Tailscale Installation Script ==="
echo "Headscale URL: $HEADSCALE_URL"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected: macOS"

    # Check if Tailscale is installed
    if ! command -v tailscale &> /dev/null; then
        echo "Installing Tailscale via Homebrew..."
        brew install tailscale
    fi

    echo "Starting Tailscale..."
    brew services start tailscale || true

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected: Linux"

    # Check if Tailscale is installed
    if ! command -v tailscale &> /dev/null; then
        echo "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
    fi

    echo "Starting Tailscale..."
    sudo systemctl enable --now tailscaled

else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Connect to Headscale
echo ""
echo "=== Connecting to Headscale ==="
echo "Run the following command to connect:"
echo ""
echo "  tailscale up --login-server=$HEADSCALE_URL"
echo ""
echo "Then register the node on Headscale server:"
echo ""
echo "  headscale nodes register --user <username> --key <nodekey>"
echo ""

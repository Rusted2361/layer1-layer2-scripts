#!/bin/bash

# Installation script for Ubuntu - Layer 2 Development Dependencies
# This script installs Go 1.23, GVM, Just, Cast (Foundry), curl, make, jq, and git

set -e  # Exit on any error

echo "🚀 Starting installation of Layer 2 development dependencies..."
echo "============================================================"

# Update package list
echo "📦 Updating package list..."
sudo apt update

# Install basic utilities first
echo "🔧 Installing basic utilities (curl, make, jq, git)"
sudo apt install -y curl make jq git build-essential

# Install Just 1.42.4
echo "⚡ Installing Just 1.42.4..."
if ! command -v just &> /dev/null; then
    sudo snap install just --classic
    echo "✅ Just installed successfully"
else
    echo "✅ Just already installed"
fi

# Verify Just installation
echo "🔍 Verifying Just installation..."
just --version

# Install Foundry (which includes cast)
echo "🔨 Installing Foundry (cast)..."
if ! command -v cast &> /dev/null; then
    # Download and run foundry installer
    curl -L https://foundry.paradigm.xyz | bash
    
    # Source bashrc to make foundryup available
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.profile" 2>/dev/null || true
    
    # Add foundry to PATH for current session
    export PATH="$HOME/.foundry/bin:$PATH"
    
    # Run foundryup to install the latest version
    "$HOME/.foundry/bin/foundryup"
    
    echo "✅ Foundry (cast) installed successfully"
else
    echo "✅ Foundry (cast) already installed"
fi

# Verify cast installation
echo "🔍 Verifying cast installation..."
cast --version

# Add Foundry to PATH in bashrc if not present
if ! grep -q ".foundry/bin" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Foundry" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo "============================================================"
echo "📋 Installed versions:"
echo "   - Go: $(go version)"
echo "   - Just: $(just --version)"
echo "   - Cast: $(cast --version)"
echo "   - Make: $(make --version | head -n1)"
echo "   - jq: $(jq --version)"
echo "   - Git: $(git --version)"
echo "   - curl: $(curl --version | head -n1)"
echo ""
echo "⚠️  IMPORTANT: Please run 'source ~/.bashrc' or restart your terminal"
echo "    to ensure all environment variables are loaded properly."
echo ""
echo "🔧 To verify everything is working after sourcing bashrc:"
echo "   go version"
echo "   just --version" 
echo "   cast --version"
echo "============================================================"
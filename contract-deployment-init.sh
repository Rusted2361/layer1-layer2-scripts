#!/bin/bash

set -e

mkdir -p layer2
cd layer2
mkdir -p bin

# Step 1: Setup Directories
echo "📁 Setting up directories..."

# Step 2: Detect Platform and Architecture
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [[ "$PLATFORM" == "darwin" && "$ARCH" == "arm64" ]]; then
  OS="mac-arm64"
elif [[ "$PLATFORM" == "darwin" && "$ARCH" == "x86_64" ]]; then
  OS="mac-amd64"
elif [[ "$PLATFORM" == "linux" && "$ARCH" == "x86_64" ]]; then
  OS="linux-amd64"
else
  echo "❌ Unsupported platform: $PLATFORM $ARCH"
  exit 1
fi

# Step 3: Download op-deployer if not already present
if [ ! -f "bin/op-deployer" ]; then
  curl -sL https://codeload.github.com/ethereum-optimism/optimism/tar.gz/refs/tags/op-deployer/v0.2.0-rc.1 -o op-deployer-v0.2.0-rc.1.tar.gz
  tar -xzf op-deployer-v0.2.0-rc.1.tar.gz
  cd optimism-op-deployer-v0.2.0-rc.1/op-deployer
  if go version | grep -q "go1.23.0"; then
      echo "✅ Go 1.23.0 is already installed"
  else
      echo "⬇️ Installing Go 1.23.0 using gvm..."
      gvm install go1.23.0
      gvm use go1.23.0 --default
      echo "✅ Go 1.23.0 installed and set as default"
  fi
  echo "pwd: $(pwd)"
  just
  cp bin/op-deployer ../../../layer2/bin/
  # rm -rf op-deployer-v0.2.0-rc.1.tar.gz optimism-op-deployer-v0.2.0-rc.1

cd ../../../layer2
fi

echo "pwd: $(pwd)"

DEPLOYER_BIN="bin/op-deployer"

echo "DEPLOYER_BIN: $DEPLOYER_BIN"
# Step 4: Initialize Deployment Directory
echo "🚀 Initializing deployment directory..."
"$DEPLOYER_BIN" init \
  --l1-chain-id 20253 \
  --l2-chain-ids 20254 \
  --workdir .deployer \
  --intent-type custom

echo ""
echo "✅ Layer 2 deployment initialized. Workdir: .deployer created"

echo "create .envrc file in .deployer"
if [ ! -d "optimism" ]; then
  git clone https://github.com/ethereum-optimism/optimism.git 
  cd optimism
  git checkout op-node/v1.13.3
  echo "Paste output from following to .envrc"
  ./packages/contracts-bedrock/scripts/getting-started/wallets.sh -o .deployer/.envrc
  cd ..
fi
if [ ! -f ".deployer/.envrc" ]; then
  ./optimism/packages/contracts-bedrock/scripts/getting-started/wallets.sh > .deployer/.envrc
fi
# Add additional environment variables to .envrc
cat >> .deployer/.envrc << 'EOF'

# L1 Chain ID
export L1_CHAIN_ID=20253

# L2 Chain IDs
export L2_CHAIN_IDS=20254

# L1 Deployer Admin
export L1_DEPLOYER_ADMIN=0x123463a4b065722e99115d6c222f267d9cabb524

EOF

echo "✅ .envrc file created at $(pwd)/.deployer/.envrc"
ls -la .deployer/.envrc
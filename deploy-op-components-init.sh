cd layer2

source .deployer/.envrc


echo "creating op-geth"
if [ ! -d "op-geth" ]; then
    git clone https://github.com/ethereum-optimism/op-geth.git
fi
cd op-geth
git checkout 2b9abb39077cb88f6e8a513f09a5ea2c2569dfed
if go version | grep -q "go1.23.0"; then
      echo "✅ Go 1.23.0 is already installed"
  else
      echo "⬇️ Installing Go 1.23.0 using gvm..."
      gvm install go1.23.0
      gvm use go1.23.0 --default
      echo "✅ Go 1.23.0 installed and set as default"
  fi

if [ ! -f "bin/geth" ]; then
    make geth
    cp build/bin/geth bin/geth
fi

cd ..

echo "creating op-node"
if [ ! -d "optimism" ]; then
    git clone https://github.com/ethereum-optimism/optimism.git
fi
cd optimism
echo "moved in pwd: $(pwd) "
echo "building op-node"
git checkout c8b9f62736a7dad7e569719a84c406605f4472e6
cd op-node
just
echo "op-node created and saved in bin"
cp ./bin/op-node ../../bin
cd ..


echo "creating op-proposer"
cd op-proposer
just
cp ./bin/op-proposer ../../bin
cd ..

echo "creating op-batcher"
cd op-batcher
just
cp ./bin/op-batcher ../../bin
cd ../../
echo "pwd: $(pwd)"

mkdir sequencer-node proposer-node batcher-node

cd sequencer-node
cp ../../layer2/.deployer/genesis.json .
cp ../../layer2/.deployer/rollup.json .

mkdir scripts
# Generate JWT secret in the sequencer directory
openssl rand -hex 32 > jwt.txt
 
# Set appropriate permissions
chmod 600 jwt.txt

echo "🔧 Setting up sequencer .env file..."

# Get public IP automatically
echo "🌐 Getting public IP address..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "📍 Public IP detected: $PUBLIC_IP"

echo ""
echo "Please provide the following configuration values:"

# Ask for L1 RPC URL
read -p "L1 RPC URL [default: http://43.205.146.113:8545]: " L1_RPC_INPUT
L1_RPC_URL=${L1_RPC_INPUT:-http://43.205.146.113:8545}

# Ask for L1 Beacon URL  
read -p "L1 Beacon URL [default: http://43.205.146.113:3500]: " L1_BEACON_INPUT
L1_BEACON_URL=${L1_BEACON_INPUT:-http://43.205.146.113:3500}

read -p "Enter L2 RPC URL [default: http://localhost:9545] <op-geth-ip:9545>:" INPUT_L2_RPC
L2_RPC_URL=${INPUT_L2_RPC:-http://localhost:9545}

read -p "Enter L2 Auth URL [default: http://localhost:9551] <op-geth-ip:9551>:" INPUT_L2_AUTH_RPC_URL
L2_AUTH_RPC_URL=${INPUT_L2_AUTH_RPC_URL:-http://localhost:9551}

# Ask for Rollup RPC URL
read -p "Rollup RPC URL [default: http://localhost:8547] <op-node-ip:8547>:" ROLLUP_RPC_INPUT
ROLLUP_RPC_URL=${ROLLUP_RPC_INPUT:-http://localhost:8547}

# Ask for private key
read -p "Private Key [default: 0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622]: " PRIVATE_KEY_INPUT
PRIVATE_KEY=${PRIVATE_KEY_INPUT:-0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622}

# Ask for public IP confirmation
read -p "P2P Advertise IP [detected: $PUBLIC_IP]: " PUBLIC_IP_INPUT
P2P_ADVERTISE_IP=${PUBLIC_IP_INPUT:-$PUBLIC_IP}

echo ""
echo "Creating .env file with your configuration..."

# Create sequencer .env file
cat > .env << EOF
# L1 Configuration
L1_RPC_URL=$L1_RPC_URL
L1_BEACON_URL=$L1_BEACON_URL
L2_RPC_URL=$L2_RPC_URL
L2_AUTH_RPC_URL=$L2_AUTH_RPC_URL

# Sequencer configuration
SEQUENCER_ENABLED=true
SEQUENCER_STOPPED=false

# Private keys
PRIVATE_KEY=$PRIVATE_KEY

# P2P configuration
P2P_LISTEN_PORT=9222
P2P_ADVERTISE_IP=$P2P_ADVERTISE_IP

# RPC configuration
OP_NODE_RPC_PORT=8547
OP_GETH_HTTP_PORT=9545
OP_GETH_WS_PORT=9546
OP_GETH_AUTH_PORT=9551

# L2 P2P port (avoiding L1's 30303)
OP_GETH_P2P_PORT=9303

# JWT secret location
JWT_SECRET=./jwt.txt

# Network ID
OP_GETH_NETWORK_ID=20254
EOF

echo "✅ Sequencer .env file created at .env"
echo "📄 Contents:"
cat .env

echo ""
echo "🚀 Sequencer environment ready!"

cd ..
echo "🔧 Setting up proposer environment..."

# Create proposer-node directory if it doesn't exist
mkdir -p proposer-node/scripts
cd proposer-node

# Copy the state.json from .deployer directory
cp ../../layer2/.deployer/state.json .

# Extract the DisputeGameFactory address
GAME_FACTORY_ADDRESS=$(cat state.json | jq -r '.opChainDeployments[0].DisputeGameFactoryProxy')
echo "📄 DisputeGameFactory Address: $GAME_FACTORY_ADDRESS"

echo ""
echo "Please provide the following proposer configuration values:"


# Ask for private key (default from environment)
read -p "Proposer Private Key [default: $GS_PROPOSER_PRIVATE_KEY]: " PROPOSER_KEY_INPUT
PROPOSER_PRIVATE_KEY=${PROPOSER_KEY_INPUT:-$GS_PROPOSER_PRIVATE_KEY}

echo ""
echo "Creating proposer .env file..."

# Create proposer .env file
cat > .env << EOF
# L1 Configuration
L1_RPC_URL=$L1_RPC_URL

# L2 Configuration
L2_RPC_URL=$L2_RPC_URL
ROLLUP_RPC_URL=$ROLLUP_RPC_URL

# Contract addresses
GAME_FACTORY_ADDRESS=$GAME_FACTORY_ADDRESS

# Private key
GS_PROPOSER_PRIVATE_KEY=$PROPOSER_PRIVATE_KEY

# Proposer configuration
PROPOSAL_INTERVAL=600s
GAME_TYPE=1
POLL_INTERVAL=20s

# RPC configuration
PROPOSER_RPC_PORT=8560
EOF

echo "✅ Proposer .env file created at proposer-node/.env"
echo "📄 Contents:"
cat .env

echo ""
echo "🚀 Proposer environment ready!"
cd ..

echo "creating batcher-node"
cd batcher-node
mkdir scripts

# Copy deployment files
cp ../../layer2/.deployer/state.json .
cp ../../layer2/.deployer/rollup.json .

# Extract the batch inbox address
BATCH_INBOX_ADDRESS=$(cat rollup.json | jq -r '.batch_inbox_address')
echo "📄 Batch Inbox Address: $BATCH_INBOX_ADDRESS"

echo ""
echo "Please provide the following batcher configuration values:"

# Ask for private key (default from environment)
read -p "Batcher Private Key [default: $GS_BATCHER_PRIVATE_KEY]: " BATCHER_KEY_INPUT
BATCHER_PRIVATE_KEY=${BATCHER_KEY_INPUT:-$GS_BATCHER_PRIVATE_KEY}

echo ""
echo "Creating batcher .env file..."

# Create batcher .env file
cat > .env << EOF
# L1 Configuration
L1_RPC_URL=$L1_RPC_URL

# L2 Configuration
L2_RPC_URL=$L2_RPC_URL
ROLLUP_RPC_URL=$ROLLUP_RPC_URL

# Contract addresses
BATCH_INBOX_ADDRESS=$BATCH_INBOX_ADDRESS

# Private key
BATCHER_PRIVATE_KEY=$BATCHER_PRIVATE_KEY

# Batcher configuration
POLL_INTERVAL=1s
SUB_SAFETY_MARGIN=6
NUM_CONFIRMATIONS=1
SAFE_ABORT_NONCE_TOO_LOW_COUNT=3
RESUBMISSION_TIMEOUT=30s
MAX_CHANNEL_DURATION=25

# RPC configuration
BATCHER_RPC_PORT=8548
EOF

echo "✅ Batcher .env file created at batcher-node/.env"
echo "📄 Contents:"
cat .env

echo ""
echo "🚀 Batcher environment ready!"
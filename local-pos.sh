#!/bin/bash

set -e

# === Configs ===
GETH_COMMIT="23ac8df15302bbde098cab6d711abdd24843d66a"
PRYSM_COMMIT="cb9b5e8f6e91adc8c6cdb2ca39708703e88c0b63"

# === Directories ===
mkdir -p layer1
cd layer1
mkdir -p bin

# === Check & Clone Repos ===
if [ ! -d "go-ethereum" ]; then
  echo "[1/9] Cloning Geth..."
  git clone https://github.com/ethereum/go-ethereum.git
  cd go-ethereum
  git checkout $GETH_COMMIT
  make geth
  cp ./build/bin/geth ../bin/geth
  cd ..
else
  echo "[1/9] Geth already cloned."
fi

if [ ! -d "prysm" ]; then
  echo "[2/9] Cloning Prysm..."
  git clone https://github.com/OffchainLabs/prysm.git
  cd prysm
  git checkout $PRYSM_COMMIT
  go build -o=../bin/beacon-chain ./cmd/beacon-chain
  go build -o=../bin/validator ./cmd/validator
  go build -o=../bin/prysmctl ./cmd/prysmctl
  cd ..
else
  echo "[2/9] Prysm already cloned."
fi

# === Generate jwtsecret ===
mkdir -p gethdata/geth
if [ ! -f gethdata/geth/jwtsecret ]; then
  echo "[3/9] Creating jwtsecret..."
  openssl rand -hex 32 | tr -d "\n" > gethdata/geth/jwtsecret
fi

# === Create sk.json ===
if [ ! -f sk.json ]; then
  echo "[4/9] Creating sk.json..."
  echo "2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622" > sk.json
fi

# === Create config.yml ===
if [ ! -f config.yml ]; then
  echo "[5/9] Creating config.yml..."
  cat > config.yml <<EOF
CONFIG_NAME: interop
PRESET_BASE: interop
GENESIS_FORK_VERSION: 0x03000000
ALTAIR_FORK_EPOCH: 2
ALTAIR_FORK_VERSION: 0x20000090
BELLATRIX_FORK_EPOCH: 4
BELLATRIX_FORK_VERSION: 0x20000091
TERMINAL_TOTAL_DIFFICULTY: 50
SECONDS_PER_SLOT: 12
SLOTS_PER_EPOCH: 6
DEPOSIT_CONTRACT_ADDRESS: 0x4242424242424242424242424242424242424242
EOF
fi

# === copy genesis.json ===
rm -rf genesis.json
cp ../genesis.json .


echo "⚠️  WARNING: genesis.json is empty!"
echo "Please copy the genesis.json content from this link:"
echo "https://docs.google.com/document/d/1eddhKQOPiVhzCaxpz9d3hbuTnp4GCF4tqi6-EiS0Srk/edit?tab=t.0"
echo ""

# === Initialize chain ===
rm -rf gethdata beacondata validatordata genesis.ssz 
echo "[7/9] Importing private key..."
./bin/geth --datadir=gethdata account import sk.json

echo "[8/9] Initializing Geth with genesis.json..."
./bin/geth --datadir=gethdata init genesis.json

echo "[9/9] Generating beacon genesis..."
./bin/prysmctl testnet generate-genesis \
  --num-validators=64 \
  --output-ssz=genesis.ssz \
  --chain-config-file=config.yml

# === Create password file ===
if [ ! -f password.txt ]; then
  echo "[9.1/9] Creating password.txt..."
  echo "" > password.txt
fi

# === Final Instructions ===
cat <<EOF

🚀 Setup complete!

Run in background (nohup):
===================================

Terminal 1: Geth Execution Client
---------------------------------
nohup ./bin/geth --datadir gethdata --http --http.addr 0.0.0.0 --http.port 8545 --http.api "eth,net,web3,engine" --http.corsdomain "https://remix.ethereum.org" --http.vhosts "localhost,127.0.0.1" --authrpc.addr localhost --authrpc.port 8551 --authrpc.vhosts localhost --authrpc.jwtsecret gethdata/geth/jwtsecret --allow-insecure-unlock --unlock 0x123463a4b065722e99115d6c222f267d9cabb524 --password ./password.txt --mine --nodiscover --syncmode full > geth.log 2>&1 &

Terminal 2: Beacon Chain
------------------------
nohup ./bin/beacon-chain --datadir=beacondata --min-sync-peers=0 --interop-genesis-state=genesis.ssz --interop-eth1data-votes --bootstrap-node= --chain-config-file=config.yml --chain-id=20253 --execution-endpoint=http://localhost:8551 --accept-terms-of-use --jwt-secret=gethdata/geth/jwtsecret --grpc-gateway-host=0.0.0.0 --grpc-gateway-port=3500 --rpc-host=0.0.0.0 --rpc-port=4000 > chain.log 2>&1 &

Terminal 3: Validator Client
----------------------------
nohup ./bin/validator --datadir=validatordata --accept-terms-of-use --interop-num-validators=64 --interop-start-index=0 --force-clear-db --chain-config-file=config.yml --config-file=config.yml > validator.log 2>&1 &

Terminal 4: IPC Console
----------------------------------
./bin/geth attach ipc:gethdata/geth.ipc

Inside the console, run:
> miner.start()

📋 Background Process Management:
- View logs: tail -f geth.log, tail -f chain.log, tail -f validator.log
- Stop processes: pkill -f geth, pkill -f beacon-chain, pkill -f validator
- Check running processes: ps aux | grep -E "(geth|beacon|validator)"

EOF
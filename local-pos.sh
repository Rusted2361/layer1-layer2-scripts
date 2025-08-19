#!/bin/bash

set -e

# === Configs ===
GETH_COMMIT="23ac8df15302bbde098cab6d711abdd24843d66a"
PRYSM_COMMIT="cb9b5e8f6e91adc8c6cdb2ca39708703e88c0b63"

# === Directories ===
mkdir -p layer1
cd layer1
mkdir -p bin

source  $GVM_ROOT/scripts/gvm
gvm install go1.19.13
gvm use go1.19.13
go version

# === Check & Clone Repos ===
if [ ! -d "go-ethereum" ]; then
  echo "[1/9] Cloning Geth..."
  git clone git@github.com:ethereum/go-ethereum.git
else
  echo "[1/9] Geth already cloned."
fi

cd go-ethereum
git checkout $GETH_COMMIT
make geth
cp ./build/bin/geth ../bin/geth
cd ..

if [ ! -d "prysm" ]; then
  echo "[2/9] Cloning Prysm..."
  git clone git@github.com:OffchainLabs/prysm.git
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

# === Download genesis.json ===
rm -rf genesis.json
if [ ! -f genesis.json ]; then
  echo "[6/9] Downloading genesis.json..."
  curl -s https://api.jsonbin.io/v3/qs/68a346b6ae596e708fcd5fc7 | jq '.record' > genesis.json
else
  echo "[6/9] genesis.json already exists."
fi

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

# === Final Instructions ===
cat <<EOF

🚀 Setup complete!

Now run the following in separate terminals:

Terminal 1: Geth Execution Client
---------------------------------
./bin/geth \
  --datadir gethdata \
  --http --http.addr 0.0.0.0 \
  --http.port 8545 \
  --http.api "eth,net,web3,engine" \
  --http.corsdomain "https://remix.ethereum.org" \
  --http.vhosts "localhost,127.0.0.1" \
  --authrpc.addr localhost \
  --authrpc.port 8551 \
  --authrpc.vhosts localhost \
  --authrpc.jwtsecret gethdata/geth/jwtsecret \
  --allow-insecure-unlock \
  --unlock 0x123463a4b065722e99115d6c222f267d9cabb524 \
  --password "" \
  --mine \
  --nodiscover \
  --syncmode full

Terminal 2: Beacon Chain
------------------------
./bin/beacon-chain \
  --datadir=beacondata \
  --min-sync-peers=0 \
  --interop-genesis-state=genesis.ssz \
  --interop-eth1data-votes \
  --bootstrap-node= \
  --chain-config-file=config.yml \
  --chain-id=20253 \
  --execution-endpoint=http://localhost:8551 \
  --accept-terms-of-use \
  --jwt-secret=gethdata/geth/jwtsecret

Terminal 3: Validator Client
----------------------------
./bin/validator \
  --datadir=validatordata \
  --accept-terms-of-use \
  --interop-num-validators=64 \
  --interop-start-index=0 \
  --force-clear-db \
  --chain-config-file=config.yml \
  --config-file=config.yml

Terminal 4: IPC Console (optional)
----------------------------------
./bin/geth attach ipc:gethdata/geth.ipc

Inside the console, run:
> miner.start()

EOF

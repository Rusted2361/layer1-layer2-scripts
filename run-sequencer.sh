#!/bin/bash

cd layer2/sequencer-node
#save below script to scripts/start-op-geth.sh
source .env
cp ../../layer2/op-geth/build/bin/geth .
cp ../../layer2/bin/op-node .

cat <<EOF > scripts/start-op-geth.sh
#!/bin/bash

source .env
 
# Path to the op-geth binary we built
nohup ./geth \
  --datadir=./op-geth-data \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=$OP_GETH_HTTP_PORT \
  --http.vhosts="*" \
  --http.corsdomain="*" \
  --http.api=eth,net,web3,debug,txpool,admin,personal \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=$OP_GETH_WS_PORT \
  --ws.origins="*" \
  --ws.api=eth,net,web3,debug,txpool,admin \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=$OP_GETH_AUTH_PORT \
  --authrpc.vhosts="*" \
  --authrpc.jwtsecret=$JWT_SECRET \
  --port=$OP_GETH_P2P_PORT \
  --networkid="$OP_GETH_NETWORK_ID" \
  --metrics \
  --metrics.addr=0.0.0.0 \
  --metrics.port=9001 \
  --syncmode=full \
  --gcmode=archive \
  --nodiscover \
  --maxpeers=0 \
  --rollup.disabletxpoolgossip=true \
  --ipcpath "$(pwd)/op-geth-data/geth.ipc" > opgeth.log 2>&1 &
EOF

cat > scripts/start-op-node.sh <<'EOF'
#!/bin/bash

source .env

ROLLUP_JSON=./rollup.json

# 1) Fetch the actual L2 genesis block hash (block 0) from op-geth
echo "Querying L2 genesis block hash from $L2_RPC_URL ..."
GENESIS_HASH=$(curl -s -X POST "$L2_RPC_URL" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_getBlockByNumber","params":["0x0", false]}' \
  | jq -r '.result.hash')

if [[ -z "${GENESIS_HASH}" || "${GENESIS_HASH}" == "null" ]]; then
  echo "ERROR: Could not retrieve genesis hash from $L2_RPC_URL. Is op-geth running and exposing RPC?"
  exit 1
fi

echo "L2 genesis hash from node: ${GENESIS_HASH}"

# Snapshot current value (handles both schemas)
CURRENT_HASH=$(jq -r '.genesis.l2.hash // .l2.hash // empty' "${ROLLUP_JSON}")

if [[ -z "${CURRENT_HASH}" || "${CURRENT_HASH}" == "null" ]]; then
  echo "ERROR: ${ROLLUP_JSON} missing current L2 hash (.genesis.l2.hash or .l2.hash)."
  exit 1
fi

# 2) Patch rollup.json (support both schemas)
TMP_JSON=$(mktemp)

if jq -e '.genesis.l2.hash' "${ROLLUP_JSON}" > /dev/null 2>&1; then
  jq --arg h "${GENESIS_HASH}" '.genesis.l2.hash = $h' "${ROLLUP_JSON}" > "${TMP_JSON}"
else
  jq --arg h "${GENESIS_HASH}" '.l2.hash = $h' "${ROLLUP_JSON}" > "${TMP_JSON}"
fi

mv "${TMP_JSON}" "${ROLLUP_JSON}"
echo "Updated ${ROLLUP_JSON} with L2 genesis hash."
if [[ -n "${CURRENT_HASH}" && "${CURRENT_HASH}" != "${GENESIS_HASH}" ]]; then
  echo "rollup.json hash (${CURRENT_HASH}) differed from node (${GENESIS_HASH}); updated."
fi
 
# Path to the op-node binary we built
nohup ./op-node \
  --l1=$L1_RPC_URL \
  --l1.beacon=$L1_BEACON_URL \
  --l2=$L2_AUTH_RPC_URL \
  --l2.jwt-secret=$JWT_SECRET \
  --rollup.config=./rollup.json \
  --sequencer.enabled=$SEQUENCER_ENABLED \
  --sequencer.stopped=$SEQUENCER_STOPPED \
  --sequencer.max-safe-lag=3600 \
  --verifier.l1-confs=4 \
  --p2p.disable \
  --rpc.addr=0.0.0.0 \
  --rpc.port=$OP_NODE_RPC_PORT \
  --rpc.enable-admin \
  --log.level=info > opnode.log 2>&1 &
EOF

chmod +x scripts/start-op-geth.sh
chmod +x scripts/start-op-node.sh

rm -rf op-geth-data

./geth init --datadir=./op-geth-data --state.scheme=hash ./genesis.json

echo "please run below command to start op-geth"
echo "./scripts/start-op-geth.sh"

echo "please run below command to start op-node"
echo "./scripts/start-op-node.sh"

echo "verify using commands here: https://docs.optimism.io/operators/chain-operators/deploy/sequencer-node#verify-sequencer-is-running"
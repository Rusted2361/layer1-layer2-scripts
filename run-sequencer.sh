#!/bin/bash

cd layer2/sequencer-node
#save below script to scripts/start-op-geth.sh
source .env
cp ../bin/geth .
cp ../bin/op-node .

cat <<EOF > scripts/start-op-geth.sh
#!/bin/bash

source .env
 
# Path to the op-geth binary we built
./geth \
  --datadir=./op-geth-data \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=$OP_GETH_HTTP_PORT \
  --http.vhosts="*" \
  --http.corsdomain="*" \
  --http.api=eth,net,web3,debug,txpool,admin \
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
  --syncmode=full \
  --gcmode=archive \
  --nodiscover \
  --maxpeers=0 \
  --rollup.disabletxpoolgossip=true \
  --rollup.sequencerhttp=http://localhost:$OP_NODE_RPC_PORT
EOF

cat <<EOF > scripts/start-op-node.sh
#!/bin/bash

source .env
 
# Path to the op-node binary we built
./op-node \
  --l1=$L1_RPC_URL \
  --l1.beacon=$L1_BEACON_URL \
  --l2=http://localhost:$OP_GETH_AUTH_PORT \
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
  --log.level=info 
EOF

chmod +x scripts/start-op-geth.sh
chmod +x scripts/start-op-node.sh

../bin/geth init --datadir=./op-geth-data --state.scheme=hash ./genesis.json

echo "please run below command to start op-geth"
echo "./scripts/start-op-geth.sh"

echo "please run below command to start op-node"
echo "./scripts/start-op-node.sh"

echo "verify using commands here: https://docs.optimism.io/operators/chain-operators/deploy/sequencer-node#verify-sequencer-is-running"
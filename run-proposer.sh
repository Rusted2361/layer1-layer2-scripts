cd layer2/proposer-node

echo "pwd: $(pwd)"
source .env
cat <<EOF > scripts/start-proposer.sh
#!/bin/bash
 
source .env
 
# Path to the op-proposer binary we built
nohup ../optimism/op-proposer/bin/op-proposer \
  --poll-interval=$POLL_INTERVAL \
  --rpc.port=$PROPOSER_RPC_PORT \
  --rpc.enable-admin \
  --rollup-rpc=$ROLLUP_RPC_URL \
  --l1-eth-rpc=$L1_RPC_URL \
  --private-key=$GS_PROPOSER_PRIVATE_KEY \
  --game-factory-address=$GAME_FACTORY_ADDRESS \
  --game-type=$GAME_TYPE \
  --proposal-interval=$PROPOSAL_INTERVAL \
  --num-confirmations=1 \
  --resubmission-timeout=30s \
  --wait-node-sync=true \
  --log.level=info > opproposer.log 2>&1 &
EOF

chmod +x scripts/start-proposer.sh

echo "please run below command to start proposer"
echo "./scripts/start-proposer.sh"

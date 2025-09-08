#!/bin/bash

cd layer2/batcher-node

echo "pwd: $(pwd)"
source .env

cat <<EOF > scripts/start-batcher.sh
#!/bin/bash
 
source .env
 
# Path to the op-batcher binary we built
nohup ../optimism/op-batcher/bin/op-batcher \
  --l2-eth-rpc=$L2_RPC_URL \
  --rollup-rpc=$ROLLUP_RPC_URL \
  --poll-interval=$POLL_INTERVAL \
  --sub-safety-margin=$SUB_SAFETY_MARGIN \
  --num-confirmations=$NUM_CONFIRMATIONS \
  --safe-abort-nonce-too-low-count=$SAFE_ABORT_NONCE_TOO_LOW_COUNT \
  --resubmission-timeout=$RESUBMISSION_TIMEOUT \
  --rpc.addr=0.0.0.0 \
  --rpc.port=$BATCHER_RPC_PORT \
  --rpc.enable-admin \
  --max-channel-duration=$MAX_CHANNEL_DURATION \
  --l1-eth-rpc=$L1_RPC_URL \
  --private-key=$BATCHER_PRIVATE_KEY \
  --batch-type=1 \
  --data-availability-type=auto \
  --throttle-threshold=0 \
  --throttle-always-block-size=0 \
  --metrics.addr=0.0.0.0 \
  --metrics.enabled=true \
  --metrics.port=9005 \
  --log.level=info > opbatcher.log 2>&1 &
EOF

chmod +x scripts/start-batcher.sh

echo "please run below command to start batcher"
echo "./scripts/start-batcher.sh"
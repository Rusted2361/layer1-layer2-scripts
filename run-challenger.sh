#!/bin/bash
#some prework to get the prestate
cd layer2/challenger-node

cp ../sequencer-node/genesis.json .
cp ../sequencer-node/rollup.json .
cp genesis.json ../optimism/op-program/chainconfig/configs/20254-genesis.json
cp rollup.json ../optimism/op-program/chainconfig/configs/20254-rollup.json
mkdir -p challenger-data

cd ../optimism
prestate=$(make reproducible-prestate 2>&1 | grep -A1 "Cannon64 Absolute prestate hash:" | tail -1)
echo "prestate: $prestate"

cd op-program/bin

mv prestate-mt64.bin.gz $prestate.bin.gz

#now entering to challenger-node script
cd ../../../challenger-node

CANNON_PRESTATE=../optimism/op-program/bin/$prestate.bin.gz
echo "CANNON_PRESTATE: $CANNON_PRESTATE"

# Replace CANNON_PRESTATE in .env file, or add if it doesn't exist
if grep -q "^CANNON_PRESTATE=" .env; then
    sed -i "s|^CANNON_PRESTATE=.*|CANNON_PRESTATE=$CANNON_PRESTATE|" .env
else
    echo "CANNON_PRESTATE=$CANNON_PRESTATE" >> .env
fi

echo "pwd: $(pwd)"
source .env

cat <<EOF > scripts/start-challenger.sh
#!/bin/bash
 
source .env
 
# Path to the op-challenger binary we built
nohup ../bin/op-challenger \
--trace-type permissioned,cannon \
--l1-eth-rpc=$L1_RPC_URL \
--l2-eth-rpc=$L2_RPC_URL \
--l1-beacon=$L1_BEACON \
--rollup-rpc=$ROLLUP_RPC_URL \
--game-factory-address $GAME_FACTORY_ADDRESS \
--datadir=$DATADIR \
--cannon-bin=$CANNON_BIN \
--cannon-rollup-config=$CANNON_ROLLUP_CONFIG \
--cannon-l2-genesis=$CANNON_L2_GENESIS \
--cannon-server=$CANNON_SERVER \
--cannon-prestate=$CANNON_PRESTATE \
--private-key=$CHALLENGER_PRIVATE_KEY \
--metrics.addr=0.0.0.0 \
--metrics.enabled=true \
--metrics.port=9006 > opchallenger.log 2>&1 &
EOF

chmod +x scripts/start-challenger.sh

echo "please run below command to start challenger"
echo "./scripts/start-challenger.sh"
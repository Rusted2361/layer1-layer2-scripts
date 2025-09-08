pkill -f op-geth
pkill -f op-node
pkill -f op-batcher
pkill -f op-proposer

rm -rf layer2/.op-deployer layer2/sequencer-node/op-geth-data

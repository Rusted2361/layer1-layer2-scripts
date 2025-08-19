cd layer2

./bin/op-deployer inspect genesis --workdir .deployer 20254 > .deployer/genesis.json
./bin/op-deployer inspect rollup --workdir .deployer 20254 > .deployer/rollup.json
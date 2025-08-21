cd layer2

./bin/op-deployer inspect genesis --workdir .deployer 20254 > .deployer/genesis.json
# Add prefunded account to alloc in genesis.json
jq '.alloc["0x4670399B3879a967cdD884F09ab26A4bb230825a"] = {"balance": "0xd3c21bcecceda1000000"}' .deployer/genesis.json > .deployer/genesis_tmp.json && mv .deployer/genesis_tmp.json .deployer/genesis.json
./bin/op-deployer inspect rollup --workdir .deployer 20254 > .deployer/rollup.json
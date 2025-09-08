#!/usr/bin/env bash
pgrep -f geth         | xargs -r kill -9
pgrep -f beacon-chain | xargs -r kill -9
pgrep -f validator    | xargs -r kill -9

 rm -rf layer1/validatordata layer1/beacondata layer1/gethdata layer1/chain.log layer1/validator.log layer1/geth.log layer1/genesis.ssz
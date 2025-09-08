#clean up any previous testnet
kurtosis clean -a
# run a new testnet with the given params
kurtosis run --enclave my-testnet github.com/ethpandaops/ethereum-package --args-file network_params.yml
# watch logs of geth
kurtosis service logs my-testnet cl-1-prysm-geth --follow
# watch logs of prysm beacon node
kurtosis service logs my-testnet el-1-geth-prysm --follow
# watch logs of prysm validator
kurtosis service logs my-testnet vc-1-geth-prysm --follow
#enter to docker container
kurtosis service shell my-testnet cl-1-prysm-geth
kurtosis service shell my-testnet el-1-geth-prysm
kurtosis service shell my-testnet vc-1-geth-prysm
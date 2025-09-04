cd layer2

# Source environment variables
source .deployer/.envrc

# Define private key for funding
# FUNDING_PRIVATE_KEY=0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622
FUNDING_PRIVATE_KEY=0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31
read -p "Enter L1_L1_RPC_URL [default: http://127.0.0.1:8545]: " input_L1_RPC_URL
L1_RPC_URL=${input_L1_RPC_URL:-http://127.0.0.1:8545}


echo "💰 Checking balances and funding accounts if needed..."

# Function to check balance and fund if zero
check_and_fund() {
    local address=$1
    local name=$2
    
    echo "🔍 Checking balance for $name ($address)..."
    balance=$(cast balance $address --rpc-url $L1_RPC_URL)
    
    if [ "$balance" = "0" ]; then
        echo "💸 $name has zero balance. Sending 10 ETH..."
        cast send $address \
            --value 10ether \
            --private-key $FUNDING_PRIVATE_KEY \
            --rpc-url $L1_RPC_URL
        echo "✅ Sent 10 ETH to $name"
    else
        echo "✅ $name already has balance: $(cast balance $address --rpc-url $L1_RPC_URL --ether) ETH"
    fi
}

# Check and fund all addresses
check_and_fund $GS_ADMIN_ADDRESS "GS_ADMIN_ADDRESS"
check_and_fund $GS_BATCHER_ADDRESS "GS_BATCHER_ADDRESS" 
check_and_fund $GS_PROPOSER_ADDRESS "GS_PROPOSER_ADDRESS"
check_and_fund $GS_SEQUENCER_ADDRESS "GS_SEQUENCER_ADDRESS"
check_and_fund $GS_CHALLENGER_ADDRESS "GS_CHALLENGER_ADDRESS"

echo "💰 Balance check and funding complete!"
echo ""

cast codesize 0x4e59b44847b379578588920cA78FbF26c0B4956C --rpc-url $L1_RPC_URL

output=$(cast codesize 0x4e59b44847b379578588920cA78FbF26c0B4956C --rpc-url $L1_RPC_URL)
echo "deterministic factory code [0 for not deployed, 69 for deployed]: $output"
if [ "$output" = "0" ]; then
    echo "ERROR: Deterministic deployer not found! Deploying it now..."
    cast send 0x3fAB184622Dc19b6109349B94811493BF2a45362 --value 1ether --private-key $FUNDING_PRIVATE_KEY --rpc-url $L1_RPC_URL
    cast publish --rpc-url $L1_RPC_URL 0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222
    new_output=$(cast codesize 0x4e59b44847b379578588920cA78FbF26c0B4956C --rpc-url $L1_RPC_URL)
    echo "SUCCESS: Deterministic deployer successfully deployed! Code size: $new_output"
else
    echo "SUCCESS: Deterministic deployer already deployed! Code size: $output"
fi
rm -rf .op-deployer
./bin/op-deployer apply --workdir .deployer --l1-rpc-url $L1_RPC_URL --private-key $FUNDING_PRIVATE_KEY --deployment-target=live
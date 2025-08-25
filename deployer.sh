cd layer2

# Source environment variables
source .deployer/.envrc

# Define private key for funding
FUNDING_PRIVATE_KEY=0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622
read -p "Enter RPC_URL [default: http://127.0.0.1:8545]: " input_rpc_url
RPC_URL=${input_rpc_url:-http://127.0.0.1:8545}


echo "💰 Checking balances and funding accounts if needed..."

# Function to check balance and fund if zero
check_and_fund() {
    local address=$1
    local name=$2
    
    echo "🔍 Checking balance for $name ($address)..."
    balance=$(cast balance $address --rpc-url $RPC_URL)
    
    if [ "$balance" = "0" ]; then
        echo "💸 $name has zero balance. Sending 10 ETH..."
        cast send $address \
            --value 10ether \
            --private-key $FUNDING_PRIVATE_KEY \
            --rpc-url $RPC_URL
        echo "✅ Sent 10 ETH to $name"
    else
        echo "✅ $name already has balance: $(cast balance $address --rpc-url $RPC_URL --ether) ETH"
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

rm -rf .op-deployer
./bin/op-deployer apply --workdir .deployer --l1-rpc-url $RPC_URL --private-key 0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622 --deployment-target=live
#!/bin/bash

cd layer2

RPC_URL="http://43.205.146.113:8545"
STATE_FILE=".deployer/state.json"

echo "🔍 Contract Verification Script"
echo "================================"

if [ ! -f "$STATE_FILE" ]; then
    echo "❌ Error: $STATE_FILE not found!"
    exit 1
fi

echo "📄 Extracting contract addresses from $STATE_FILE..."

# Function to verify contract code
verify_contract() {
    local address=$1
    local name=$2
    
    echo ""
    echo "🔍 Checking $name: $address"
    
    code=$(cast code $address --rpc-url $RPC_URL)
    
    if [ "$code" = "0x" ]; then
        echo "❌ $name: No code deployed (empty contract)"
    else
        code_length=${#code}
        echo "✅ $name: Contract deployed (${code_length} characters)"
    fi
}

# Extract all contract addresses from implementations deployment
echo ""
echo "📋 Implementation Contracts:"
echo "=============================="

# Extract implementation addresses
opcm_address=$(cat $STATE_FILE | grep -o '"opcmAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
delayed_weth_address=$(cat $STATE_FILE | grep -o '"delayedWETHImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
portal_address=$(cat $STATE_FILE | grep -o '"optimismPortalImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
preimage_address=$(cat $STATE_FILE | grep -o '"preimageOracleSingletonAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
mips_address=$(cat $STATE_FILE | grep -o '"mipsSingletonAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
system_config_address=$(cat $STATE_FILE | grep -o '"systemConfigImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
l1_messenger_address=$(cat $STATE_FILE | grep -o '"l1CrossDomainMessengerImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
l1_erc721_address=$(cat $STATE_FILE | grep -o '"l1ERC721BridgeImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
l1_bridge_address=$(cat $STATE_FILE | grep -o '"l1StandardBridgeImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
erc20_factory_address=$(cat $STATE_FILE | grep -o '"optimismMintableERC20FactoryImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
dispute_factory_address=$(cat $STATE_FILE | grep -o '"disputeGameFactoryImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
anchor_registry_address=$(cat $STATE_FILE | grep -o '"anchorStateRegistryImplAddress":[[:space:]]*"[^"]*"' | cut -d'"' -f4)

# Verify all implementation contracts
verify_contract "$opcm_address" "OPCM"
verify_contract "$delayed_weth_address" "DelayedWETH Implementation"
verify_contract "$portal_address" "OptimismPortal Implementation"
verify_contract "$preimage_address" "PreimageOracle Singleton"
verify_contract "$mips_address" "MIPS Singleton"
verify_contract "$system_config_address" "SystemConfig Implementation"
verify_contract "$l1_messenger_address" "L1CrossDomainMessenger Implementation"
verify_contract "$l1_erc721_address" "L1ERC721Bridge Implementation"
verify_contract "$l1_bridge_address" "L1StandardBridge Implementation"
verify_contract "$erc20_factory_address" "OptimismMintableERC20Factory Implementation"
verify_contract "$dispute_factory_address" "DisputeGameFactory Implementation"
verify_contract "$anchor_registry_address" "AnchorStateRegistry Implementation"

echo ""
echo "📋 OpChain Deployment Contracts:"
echo "=================================="

echo ""
echo "✅ Contract verification complete!"

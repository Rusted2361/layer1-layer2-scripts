#!/bin/bash

cd layer2 || exit 1

echo "📝 Customizing intent.toml file..."

# Update contract locators in intent.toml
sed -i 's|l1ContractsLocator = ""|l1ContractsLocator = "tag://op-contracts/v2.0.0-rc.1"|g' .deployer/intent.toml
sed -i 's|l2ContractsLocator = ""|l2ContractsLocator = "tag://op-contracts/v1.7.0-beta.1+l2-contracts"|g' .deployer/intent.toml

# Source .envrc to get GS_ADMIN_ADDRESS
source .deployer/.envrc

# Replace zero addresses with GS_ADMIN_ADDRESS
echo "🔄 Replacing zero addresses with GS_ADMIN_ADDRESS ($GS_ADMIN_ADDRESS)..."

sed -i "s|proxyAdminOwner = \"0x0000000000000000000000000000000000000000\"|proxyAdminOwner = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|protocolVersionsOwner = \"0x0000000000000000000000000000000000000000\"|protocolVersionsOwner = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|guardian = \"0x0000000000000000000000000000000000000000\"|guardian = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|baseFeeVaultRecipient = \"0x0000000000000000000000000000000000000000\"|baseFeeVaultRecipient = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|l1FeeVaultRecipient = \"0x0000000000000000000000000000000000000000\"|l1FeeVaultRecipient = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|sequencerFeeVaultRecipient = \"0x0000000000000000000000000000000000000000\"|sequencerFeeVaultRecipient = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|l1ProxyAdminOwner = \"0x0000000000000000000000000000000000000000\"|l1ProxyAdminOwner = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|l2ProxyAdminOwner = \"0x0000000000000000000000000000000000000000\"|l2ProxyAdminOwner = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|systemConfigOwner = \"0x0000000000000000000000000000000000000000\"|systemConfigOwner = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|challenger = \"0x0000000000000000000000000000000000000000\"|challenger = \"$GS_ADMIN_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|unsafeBlockSigner = \"0x0000000000000000000000000000000000000000\"|unsafeBlockSigner = \"$GS_SEQUENCER_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|batcher = \"0x0000000000000000000000000000000000000000\"|batcher = \"$GS_BATCHER_ADDRESS\"|g" .deployer/intent.toml
sed -i "s|proposer = \"0x0000000000000000000000000000000000000000\"|proposer = \"$GS_PROPOSER_ADDRESS\"|g" .deployer/intent.toml

# Update EIP-1559 parameters
echo "🔧 Updating EIP-1559 parameters..."
sed -i "s|eip1559DenominatorCanyon = 0|eip1559DenominatorCanyon = 250|g" .deployer/intent.toml
sed -i "s|eip1559Denominator = 0|eip1559Denominator = 50|g" .deployer/intent.toml
sed -i "s|eip1559Elasticity = 0|eip1559Elasticity = 6|g" .deployer/intent.toml

echo "✅ intent.toml updated with contract locators, admin addresses, and EIP-1559 parameters"
echo "📄 Current intent.toml content:"
cat .deployer/intent.toml

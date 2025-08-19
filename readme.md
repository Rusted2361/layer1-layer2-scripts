# Layer 1 & Layer 2 Scripts

This repository contains a collection of scripts for setting up and managing Layer 1 (Ethereum) and Layer 2 (Optimism) blockchain infrastructure.

## 📋 Script Overview

| Script | Description |
|--------|-------------|
| `local-pos.sh` | Cleans and initializes a fresh PoS Geth node, Prysm beacon node, Prysm validator node, Geth JS IPC console for testing purposes, and exposes Remix for contract deployment and testing |
| `contract-deployment-init.sh` | Performs all pre-work required for contract deployments including keypair creation for L2 components, initial intent file, and `.envrc` file |
| `customize-intent.sh` | Fills all necessary fields of `intent.toml` from `.envrc` with valid values |
| `deployer.sh` | Deploys all the contracts |
| `verify-contracts.sh` | Verifies all the contracts |
| `create-artifacts.sh` | Creates `rollup.json` and `state.json` artifacts |
| `deploy-op-components-init.sh` | Creates all important execution files like op-geth, op-node, op-batcher, op-proposer. Also creates relevant environments for all components |
| `run-sequencer.sh` | Outputs command to execute op-geth and op-node |
| `run-proposer.sh` | Outputs command to execute op-proposer |
| `run-batcher.sh` | Outputs command to execute batcher |

## 🚀 Usage Instructions

⚠️ **Important**: Please run the scripts in the exact order they are listed above.

### Prerequisites
- Ensure you have the necessary permissions to execute shell scripts
- Make sure all required dependencies are installed

### Execution Order
1. `./local-pos.sh`
2. `./contract-deployment-init.sh`
3. `./customize-intent.sh`
4. `./deployer.sh`
5. `./verify-contracts.sh`
6. `./create-artifacts.sh`
7. `./deploy-op-components-init.sh`
8. `./run-sequencer.sh`
9. `./run-proposer.sh`
10. `./run-batcher.sh`

## 📁 Repository Structure

```
scripts-for-layer1-layer2/
├── local-pos.sh
├── contract-deployment-init.sh
├── customize-intent.sh
├── deployer.sh
├── verify-contracts.sh
├── create-artifacts.sh
├── deploy-op-components-init.sh
├── run-sequencer.sh
├── run-proposer.sh
├── run-batcher.sh
└── readme.md
```

## 🔧 Configuration

The scripts work together to create a complete Layer 1 and Layer 2 blockchain setup. Make sure to review and configure any environment variables or configuration files as needed before execution.

## 📝 Notes

- These scripts are designed for development and testing purposes
- Ensure proper network connectivity and permissions before running
- Review each script's output for any errors or warnings
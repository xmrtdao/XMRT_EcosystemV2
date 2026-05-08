# XMRT Ecosystem V2 Deployment Guide

## Prerequisites
- Node.js 18+
- A wallet with Sepolia ETH (get from https://sepoliafaucet.com)

## Setup
```bash
cd contracts
npm install
# Create .env file:
# PRIVATE_KEY=0x...
# SEPOLIA_RPC=https://rpc.sepolia.org
# ETHERSCAN_API_KEY=...
```

## Deploy to Sepolia Testnet
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## Verify on Etherscan
```bash
npx hardhat verify --network sepolia <TOKEN_ADDRESS> "XMRT Token" "XMART" 18
npx hardhat verify --network sepolia <GOVERNOR_ADDRESS> <TOKEN_ADDRESS> <DEPLOYER_ADDRESS>
```

## Networks Configured
- `hardhat` — local devnet
- `sepolia` — Ethereum testnet
- `fuji` — Avalanche testnet
- `mainnet` — Avalanche mainnet

## Contracts
| Contract | File | Purpose |
|---|---|---|
| XMRT Token | `contracts/core/ERC20.sol` | Governance token |
| ERC20Votes | `contracts/core/ERC20Votes.sol` | Voting power |
| Governor | `contracts/core/Governor.sol` | DAO governance |
| Bridge | `contracts/bridges/Bridge.sol` | Cross-chain bridge |

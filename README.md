# XMRT Ecosystem V2

This repository serves as the foundational monorepo for the XMRT Ecosystem, encompassing various components crucial for building a decentralized autonomous organization (DAO) powered by AI agents and blockchain technology. It includes smart contracts, AI agent implementations, decentralized applications (dApps), and infrastructure configurations.

## Project Overview

The XMRT Ecosystem V2 aims to provide a comprehensive framework for developing and deploying AI-driven DAOs. It integrates cutting-edge technologies such as zero-knowledge proofs (ZKPs) for enhanced privacy and verifiability, and the Eliza AI framework for autonomous organizational management.

Key features include:
- **Smart Contracts**: Core logic for DAO governance, treasury management, and token operations.
- **AI Agents**: Intelligent agents built with the Eliza framework for decision-making, analysis, and automation.
- **Decentralized Applications (dApps)**: User interfaces for interacting with the DAO and its AI agents.
- **Zero-Knowledge Proofs**: Implementations for privacy-preserving operations (e.g., anonymous voting).
- **Infrastructure**: Configuration and deployment scripts for various components.

## Directory Structure

This monorepo is organized into the following key directories:

- `ai-agents/`: Contains the implementation of Eliza AI agents responsible for various DAO functions (e.g., governance, treasury, security).
- `apps/`: Houses decentralized applications (dApps) that provide user interfaces for interacting with the XMRT DAO. This may include the frontend for the XMRT DAO prototype.
- `contracts/`: Contains Solidity smart contracts for the XMRT token, DAO governance, treasury management, and other blockchain-related functionalities.
- `docs/`: Documentation for the XMRT Ecosystem, including technical specifications, API references, and user guides.
- `infrastructure/`: Configuration files and scripts for deploying and managing the XMRT Ecosystem components (e.g., blockchain nodes, AI agent servers).
- `packages/`: A general directory for shared code, utilities, or common libraries used across different parts of the monorepo.

## Setup and Installation

To set up the XMRT Ecosystem V2 for local development, follow these general steps. Specific instructions for each component (AI agents, dApps, contracts) will be detailed within their respective directories.

### Prerequisites

- Node.js (LTS version recommended)
- npm or pnpm (pnpm is recommended for monorepos)
- Python 3.9+
- Git
- Docker (optional, for containerized deployments)
- Foundry or Hardhat (for smart contract development)

### General Installation Steps

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/DevGruGold/XMRT_EcosystemV2.git
    cd XMRT_EcosystemV2
    ```

2.  **Install monorepo dependencies (using pnpm):**
    ```bash
    pnpm install
    ```
    *If you prefer npm, you might need to adjust your setup for monorepo management (e.g., using Lerna or npm workspaces).* 

3.  **Set up individual components:**
    Navigate into each relevant directory (`ai-agents/`, `apps/`, `contracts/`, `infrastructure/`) and follow their specific `README.md` files for detailed setup, configuration, and running instructions.

## Contributing

We welcome contributions to the XMRT Ecosystem V2! Please refer to the `CONTRIBUTING.md` file for guidelines on how to contribute, including:

- Reporting bugs
- Suggesting enhancements
- Submitting pull requests
- Code style and conventions

## License

This project is licensed under the [MIT License](LICENSE).


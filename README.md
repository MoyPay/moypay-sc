# MoyPay - DeFi Payroll Management System

[![Foundry](https://img.shields.io/badge/Foundry-2024.01-blue.svg)](https://getfoundry.sh/)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-green.svg)](https://soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

MoyPay is a decentralized payroll management system that enables organizations to manage employee salaries, automate payments, and integrate with various DeFi earning protocols. Built on Core with Foundry framework.

## 🚀 Features

- **Decentralized Payroll Management**: Create and manage organizations with employee salary structures
- **Automated Salary Streaming**: Real-time salary distribution with configurable periods
- **DeFi Integration**: Earn yields on deposited funds through multiple protocols (Morpho, Compound, Aave, etc.)
- **Employee Management**: Add, remove, and manage employee status and salary information
- **Multi-Protocol Support**: Integration with various DeFi vaults for yield generation
- **Offramp Support**: Direct withdrawal and offramp functionality for employees

## 📋 Table of Contents

- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Scripts](#scripts)
- [Contributing](#contributing)

## 🏗️ Architecture

### Core Contracts

- **`Factory.sol`**: Factory contract for creating new organizations
- **`Organization.sol`**: Main contract managing payroll, employees, and DeFi integrations
- **`EarnStandard.sol`**: Standard interface for DeFi earning protocols

### Key Features

- **Employee Management**: Add employees with salary and streaming start dates
- **Salary Streaming**: Real-time salary distribution with 30-day periods
- **DeFi Integration**: Multiple earning protocols for yield generation
- **Auto-Earn**: Automated yield earning for employees
- **Withdrawal System**: Flexible withdrawal options including offramp support

## 🛠️ Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) (latest version)
- Node.js (for additional tooling)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd moypay
   ```

2. **Install dependencies**
   ```bash
   forge install
   ```

3. **Build the project**
   ```bash
   forge build
   ```

## 🚀 Usage

### Build

```bash
forge build
```

### Test

```bash
forge test
```

Run specific test file:
```bash
forge test --match-contract MoyPay
```

### Format Code

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Local Development

Start local Anvil node:
```bash
anvil
```

## 🧪 Testing

The project includes comprehensive tests covering:

- Organization creation and management
- Employee salary operations
- DeFi protocol integrations
- Withdrawal and offramp functionality
- Auto-earn features

Run tests with:
```bash
forge test
```

For verbose output:
```bash
forge test -vvv
```

## 🚀 Deployment

### Core Testnet Deployment

1. **Set environment variables**
   ```bash
   export PRIVATE_KEY="your_private_key"
   export ADDRESS="your_address"
   ```

2. **Deploy contracts**
   ```bash
   forge script script/MoyPay.s.sol:MoyPayScript --rpc-url https://rpc.test2.btcs.network --broadcast --verify
   ```

### Mainnet Deployment

Update the RPC URL and run:
```bash
forge script script/MoyPay.s.sol:MoyPayScript --rpc-url <mainnet_rpc> --broadcast --verify
```

## 📜 Scripts

### Available Scripts

- **`MoyPay.s.sol`**: Main deployment script
- **`Shortcut_CreateOrganization.s.sol`**: Quick organization creation
- **`Shortcut_DepositWithdraw.s.sol`**: Deposit and withdrawal operations
- **`Shortcut_Earning.s.sol`**: DeFi earning operations
- **`Shortcut_EmployeeManagement.s.sol`**: Employee management operations
- **`Shortcut_Faucets.s.sol`**: Faucet interactions
- **`Shortcut_Offramp.s.sol`**: Offramp functionality

### Running Scripts

```bash
# Deploy main contracts
forge script script/MoyPay.s.sol:MoyPayScript --rpc-url <rpc_url> --private-key <private_key>

# Create organization
forge script script/Shortcut_CreateOrganization.s.sol:CreateOrganizationScript --rpc-url <rpc_url> --private-key <private_key>

# Employee management
forge script script/Shortcut_EmployeeManagement.s.sol:EmployeeManagementScript --rpc-url <rpc_url> --private-key <private_key>
```

## 🔧 Configuration

### Foundry Configuration

The project uses Foundry with the following configuration:

- **Solidity Version**: ^0.8.20
- **RPC Endpoints**: Core testnet configured
- **Linting**: Excludes mixed-case variable and function warnings

### Environment Variables

Required environment variables:
- `PRIVATE_KEY`: Your deployment private key
- `ADDRESS`: Your wallet address

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Solidity best practices
- Write comprehensive tests for new features
- Update documentation for API changes
- Use Foundry's testing framework

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)

## 📞 Support

For questions and support:
- Open an issue on GitHub
- Check the documentation
- Review the test files for usage examples

---

**Built with ❤️ using Foundry**

# Synth-Stocks: Synthetic Stock Index Trading

A decentralized synthetic asset protocol built on the Stacks blockchain that allows users to gain exposure to major stock indices without holding actual shares.

## 🌟 Overview

Synth-Stocks enables users to mint synthetic tokens representing major stock indices (S&P 500, NASDAQ, FTSE 100) by providing STX as collateral. This creates a decentralized way to trade stock market exposure using cryptocurrency.

## 🎯 Supported Indices

- **sSP500** - Synthetic S&P 500 Index
- **sNASDAQ** - Synthetic NASDAQ Composite Index  
- **sFTSE** - Synthetic FTSE 100 Index

## ⚡ Key Features

### Collateralized Minting
- Mint synthetic tokens by depositing STX as collateral
- Minimum 150% collateralization ratio ensures system stability
- Over-collateralization protects against price volatility

### Oracle Price Feeds
- Real-time price updates from authorized oracles
- Price staleness protection prevents outdated data usage
- Secure oracle address management by contract owner

### Liquidation System
- Automatic liquidation of undercollateralized positions
- 5% liquidation reward incentivizes community participation
- Maintains system health and solvency

### Token Transfer
- Transfer synthetic tokens between users
- Maintain positions while trading exposure
- No need to burn and re-mint for transfers

## 🚀 Getting Started

### Prerequisites
- Stacks wallet (e.g., Hiro Wallet)
- STX tokens for collateral
- Access to Stacks testnet or mainnet

### Deployment
```bash
# Clone the repository
git clone <repository-url>

# Deploy using Clarinet
clarinet deploy --network=testnet
```

## 📖 Usage Guide

### Minting Synthetic Tokens

```clarity
;; Mint 100 sSP500 tokens (index-id: 1)
(contract-call? .synth-stocks mint-synthetic u1 u100)
```

**Requirements:**
- Sufficient STX balance for collateral (150% of token value)
- Valid index ID (1=S&P500, 2=NASDAQ, 3=FTSE)

### Burning Tokens & Retrieving Collateral

```clarity
;; Burn 50 sSP500 tokens and get collateral back
(contract-call? .synth-stocks burn-synthetic u1 u50)
```

### Transferring Tokens

```clarity
;; Transfer 25 sSP500 tokens to another address
(contract-call? .synth-stocks transfer-synthetic u1 u25 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Liquidating Positions

```clarity
;; Liquidate an undercollateralized position
(contract-call? .synth-stocks liquidate-position 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u1)
```

## 🔍 Read-Only Functions

### Check Token Balance
```clarity
(contract-call? .synth-stocks get-synthetic-balance 'SP... u1)
```

### View Position Health
```clarity
(contract-call? .synth-stocks is-position-healthy 'SP... u1)
```

### Get Index Information
```clarity
(contract-call? .synth-stocks get-stock-index u1)
```

### Calculate Required Collateral
```clarity
(contract-call? .synth-stocks calculate-required-collateral u1 u100)
```

## ⚙️ Admin Functions

### Set Oracle Address (Owner Only)
```clarity
(contract-call? .synth-stocks set-oracle-address 'SP...)
```

### Update Price (Oracle Only)
```clarity
(contract-call? .synth-stocks update-price u1 u455000) ;; $4,550.00
```

### Set Collateralization Ratio (Owner Only)
```clarity
(contract-call? .synth-stocks set-collateralization-ratio u150) ;; 150%
```

## 📊 Contract Architecture

### Data Structures

**Stock Indices Map**
```clarity
{
  name: "S&P 500 Synthetic",
  symbol: "sSP500", 
  price: u450000,        ;; Price scaled by 100
  last-updated: u12345,  ;; Block height
  total-supply: u1000000,
  is-active: true
}
```

**User Positions Map**
```clarity
{
  synthetic-tokens: u100,     ;; Amount of synthetic tokens
  collateral-stx: u150000000, ;; STX collateral in microSTX
  last-interaction: u12345    ;; Last interaction block
}
```

### Error Codes
- `u100` - Owner only operation
- `u101` - Invalid amount
- `u102` - Insufficient balance  
- `u103` - Invalid index
- `u104` - Oracle not set
- `u105` - Price stale
- `u106` - Insufficient collateral
- `u107` - Below liquidation threshold

## 🛡️ Security Features

### Collateralization
- 150% minimum collateral requirement
- Real-time position health monitoring
- Automatic liquidation protection

### Oracle Security
- Single authorized oracle address
- Price staleness checks
- Owner-controlled oracle updates

### Access Control
- Owner-only administrative functions
- Oracle-only price updates
- User-controlled position management

## 🎯 Use Cases

### Traders
- Gain exposure to traditional stock indices using crypto
- Hedge cryptocurrency positions with stock market exposure
- Access global markets 24/7 without traditional brokers

### DeFi Protocols
- Use synthetic tokens as collateral in other protocols
- Create yield farming strategies with stock exposure
- Build composite indices and investment products

### Arbitrageurs
- Profit from price differences between synthetic and real indices
- Liquidate undercollateralized positions for rewards
- Maintain system health while earning fees

## 🔧 Development

### Testing
```bash
# Run contract tests
clarinet test

# Check contract syntax
clarinet check
```

### Local Development
```bash
# Start local blockchain
clarinet integrate

# Deploy to local network
clarinet deploy --network=devnet
```

## ⚠️ Risk Considerations

### Price Risk
- Synthetic token prices track underlying indices
- Price volatility can affect collateral requirements
- Oracle failures could impact system functionality

### Liquidation Risk
- Positions below 150% collateral face liquidation
- Market volatility can trigger unexpected liquidations
- Users should monitor collateral ratios closely

### Smart Contract Risk
- Code has been designed with security in mind
- Users should understand contract mechanics
- Consider starting with small positions

## 🛣️ Roadmap

### Phase 1 (Current)
- ✅ Core synthetic asset functionality
- ✅ Basic oracle integration
- ✅ Liquidation system

### Phase 2 (Planned)
- [ ] Multiple oracle support
- [ ] Dynamic fee structure
- [ ] Governance token integration

### Phase 3 (Future)
- [ ] Cross-chain bridge integration
- [ ] Advanced trading features
- [ ] Mobile application

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## ⚖️ Disclaimer

This smart contract is for educational and experimental purposes. Users should:
- Understand the risks involved
- Only invest what they can afford to lose  
- Conduct their own research
- Consider regulatory implications in their jurisdiction

The synthetic tokens do not represent ownership in actual stocks or indices and are purely derivative instruments backed by STX collateral.
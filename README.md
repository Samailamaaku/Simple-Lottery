```md:README.md
# 🎰 Simple Lottery Smart Contract

A decentralized lottery system built on Stacks blockchain using Clarity smart contracts. This project demonstrates pseudo-randomness, fairness mechanisms, and access control patterns in blockchain development.

## 🌟 Features

- 🎲 **Fair Random Selection**: Uses VRF seed and block hash for pseudo-random winner selection
- 🔐 **Access Control**: Only authorized addresses can manage lottery operations
- 💰 **Automatic Prize Distribution**: 90% to winner, 10% platform fee
- 🛡️ **Emergency Controls**: Stop lottery and refund participants if needed
- 📊 **Lottery History**: Track past winners and statistics
- ⚡ **Real-time Status**: Check active lottery status and participation

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo>
cd simple-lottery
clarinet check
```

### 🎮 Usage

#### 1. Initialize Contract
```clarity
(contract-call? .simple-lottery initialize)
```

#### 2. Start a New Lottery
```clarity
(contract-call? .simple-lottery start-lottery u1000000) ;; 1 STX entry fee
```

#### 3. Enter the Lottery
```clarity
(contract-call? .simple-lottery enter-lottery)
```

#### 4. End Lottery and Pick Winner
```clarity
(contract-call? .simple-lottery end-lottery)
```

#### 5. Check Lottery Status
```clarity
(contract-call? .simple-lottery get-lottery-status)
```

## 🔧 Admin Functions

### Add Authorized Address
```clarity
(contract-call? .simple-lottery add-authorized-address 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Emergency Stop
```clarity
(contract-call? .simple-lottery emergency-stop)
```

### Set Entry Fee
```clarity
(contract-call? .simple-lottery set-entry-fee u2000000) ;; 2 STX
```

## 📋 Contract Functions

### Public Functions
- `initialize()` - Initialize contract and set owner as authorized
- `start-lottery(fee)` - Start new lottery with entry fee
- `enter-lottery()` - Join current lottery
- `end-lottery()` - End lottery and select winner
- `emergency-stop()` - Stop lottery and refund participants
- `add-authorized-address(address)` - Add authorized admin
- `remove-authorized-address(address)` - Remove admin access
- `set-entry-fee(fee)` - Update entry fee for next lottery

### Read-Only Functions
- `get-lottery-status()` - Current lottery information
- `is-participant(address)` - Check if address participated
- `is-address-authorized(address)` - Check admin status
- `get-lottery-history(round)` - Historical lottery data
- `get-current-winner()` - Last lottery winner
- `get-contract-balance()` - Contract STX balance

## 🎯 How It Works

1. **🎪 Lottery Lifecycle**: Admin starts lottery → Users enter → Admin ends → Winner selected
2. **🎲 Random Selection**: Combines VRF seed and block hash for fairness
3. **💸 Prize Distribution**: 90% to winner, 10% platform fee
4. **🔒 Access Control**: Only authorized addresses can manage lottery
5. **🆘 Safety Features**: Emergency stop with full refunds

## 🧪 Testing

```bash
clarinet test
```

## 🛠️ Development

### Project Structure
```
├── contracts/
│   └── simple-lottery.clar
├── tests/
├── Clarinet.toml
└── README.md
```

### Key Concepts Demonstrated
- **Pseudo-randomness** using blockchain data
- **Access control** patterns
- **State management** in Clarity
- **Error handling** best practices
- **STX transfers** and fee collection

## ⚠️ Security Notes

- Uses pseudo-randomness (not cryptographically secure)
- Suitable for educational purposes and small-scale lotteries
- Admin controls provide necessary safety mechanisms
- Always test thoroughly before mainnet deployment

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 📄 License

MIT License - feel free to use for learning and development!

---

Built with ❤️ using Clarity and Stacks blockchain
```

**Git Commit Message:**
```
feat: implement simple lottery smart contract with access control and pseudo-random winner selection
```

**GitHub Pull Request Title:**
```
🎰 Add Simple Lottery Smart Contract with Access Control System
```

**GitHub Pull Request Description:**
```
## 🎯 Summary
Implements a complete lottery smart contract system with access control mechanisms for educational purposes.

## ✨ Features Added
- **Simple Lottery System**: Users can enter lottery pools with configurable entry fees
- **Pseudo-Random Winner Selection**: Uses VRF seed and block hash for fair winner selection
- **Access Control**: Authorization system for admin functions
- **Prize Distribution**: Automatic 90/10 split between winner and platform
- **Emergency Controls**: Safety mechanisms with full refund capability
- **Lottery History**: Track past winners and statistics
- **Comprehensive Error Handling**: Robust error management throughout

## 🔧 Technical Implementation
- 150+ lines of clean Clarity code
- Proper state management with data variables and maps
- STX transfer functionality for payments and prizes
- Read-only functions for status checking
- Private helper functions for internal operations

## 📚 Educational Value
Perfect for learning:
- Pseudo-randomness in blockchain
- Access control patterns
- State management in smart contracts
- STX token handling
- Error handling best practices

## 🧪 Testing
- All functions tested and validated
- Error cases properly handled
- Contract initialization verified
- Access control mechanisms confirmed

Ready for deployment and educational use! 🚀
```


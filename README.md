```markdown
# UFO Dollar - Protocol Core & Smart Contracts

The official smart contract architecture for **UFO Dollar**, a privacy-preserving, USD-pegged settlement stablecoin built on BNB Smart Chain (BSC).

UFO is designed to provide a highly secure, zero-slippage settlement layer for B2B cross-border trade and institutional fund clearing.

## 🔗 Live Deployments (BSC Mainnet)

*   **UFOVault (Dual-Collateral Core):** [0x62Eaf08612c77F944265DE421F3Bed054531cC9C](https://bscscan.com/address/0x62Eaf08612c77F944265DE421F3Bed054531cC9C)
*   **UFOToken (ERC20):** [0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB](https://bscscan.com/address/0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB)

## ✨ Core Architecture

### 1. Multi-Collateral Resilience (Risk Isolation)
To mitigate the risk of a single stablecoin issuer freezing funds, `UFOVault` accepts **both USDT and USDC** as collateral. Reserves are isolated independently on-chain (`mapping(address => uint256) public totalReserves`). If one pool is frozen, the other remains operational.

### 2. Strict 1:1 USD Peg (Zero-Slippage)
Unlike AMM-based DEXs, UFO does not rely on liquidity pools. `1 USDT/USDC` = `$1.00 USD` = `1 UFO` (minus a 0.5% protocol fee). There is **zero slippage** for any transaction size.

### 3. Oracle-Free Stability
The `UFOVault` does not rely on external price feeds. The exchange rate is mathematically hardcoded to 1:1. This eliminates oracle manipulation and flash-loan price attacks.

### 4. Closed-Loop Architecture
UFO is not listed on public exchanges and has no public liquidity pools. Enterprise trade secrets and transaction sizes are shielded from public block explorers and on-chain analysts.

## 🛠 Tech Stack
*   **Smart Contracts:** Solidity `^0.8.20`
*   **Framework:** Foundry (Forge)
*   **Libraries:** OpenZeppelin (Security, ReentrancyGuard, Pausable, AccessControl)

## 🚀 Local Development & Testing
Ensure [Foundry](https://book.getfoundry.sh/getting-started/installation) is installed.

```bash
git clone https://github.com/ufodollar/bsc-vault.git
cd bsc-vault
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge build
forge test
```

Deployment to BSC Mainnet

```bash
forge create src/UFOVault.sol:UFOVault \
  --rpc-url https://bsc-dataseed.binance.org \
  --private-key $PRIVATE_KEY \
  --constructor-args \
  0x55d398326f99059fF775485246999027B3197955 \
  0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d \
  0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB \
  <FEE_RECIPIENT_ADDRESS>
```

🛡 Security & Transparency

· Role-Based Access Control (RBAC): Only the UFOVault contract holds the MINTER_ROLE and BURNER_ROLE. No arbitrary minting is possible.
· Emergency Pause: Pausable mechanism to halt transactions in case of vulnerabilities.
· On-Chain Verifiability: All vault balances and fee distributions are fully verifiable on BscScan.

📄 License

This project is licensed under the MIT License.

```
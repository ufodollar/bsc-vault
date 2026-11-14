

UFO Dollar - Smart Contracts & Protocol Core

The official smart contract architecture for UFO Dollar, a universal, USD-pegged settlement stablecoin built on BNB Smart Chain (BSC).

UFO is designed to provide a highly secure, zero-slippage, and privacy-preserving settlement layer for B2B cross-border trade, enterprise payroll, and global payments.

🔗 Live Deployments (BSC Mainnet)

· UFOVault (Dual-Collateral Core): 0x62Eaf08612c77F944265DE421F3Bed054531cC9C
· UFOToken (ERC20): 0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB

✨ Core Architecture & Features

1. Multi-Collateral Resilience (Risk Isolation)

To mitigate the systemic risk of a single stablecoin issuer (e.g., Tether or Circle) freezing funds, UFOVault accepts both USDT and USDC as minting collateral.

· The reserves for USDT and USDC are recorded and isolated independently on-chain (mapping(address => uint256) public totalReserves).
· If one asset pool is compromised or frozen by external forces, the other pool remains fully operational, ensuring uninterrupted redemption for merchants.

2. Strict 1:1 USD Peg (Zero-Slippage)

Unlike AMM-based DEXs, UFO does not rely on liquidity pools.

· 1 USDT/USDC = $1.00 USD = 1 UFO (minus a 0.5% protocol fee).
· There is no slippage, regardless of transaction size. This provides a highly predictable settlement route for institutional traders.

3. Oracle-Free Stability

The UFOVault contract does not rely on external price feeds (like Chainlink) to calculate minting rates. The exchange rate is mathematically hardcoded to 1:1. This eliminates the risk of oracle manipulation or flash-loan price attacks.

4. Closed-Loop Settlement

UFO is not listed on traditional exchanges and has no public liquidity pools. It operates as a permissionless settlement network, keeping enterprise trade secrets away from public block explorers and isolating the asset from market speculation.

5. Bilateral Settlement Fee (0.5%)

A transparent 0.5% protocol fee is applied on both deposit (Mint) and withdraw (Redeem).

· The fee funds ongoing infrastructure maintenance, smart contract audits, and global developer adoption.
· It is entirely not-for-profit and is routed directly to a designated treasury address.

🛠 Tech Stack

· Smart Contracts: Solidity ^0.8.20
· Framework: Foundry (Forge)
· Libraries: OpenZeppelin Contracts (Security, ReentrancyGuard, Pausable, AccessControl)
· CI/CD: GitHub Actions (Automated deployment and role management)

🚀 Local Development

Prerequisites

· Foundry installed.

1. Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
```

2. Compile Contracts

```bash
forge build
```

3. Run Tests

```bash
forge test
```

4. Deploy to BSC Mainnet

Ensure your .env contains your PRIVATE_KEY. Run the deployment script or use the provided GitHub Actions workflow (deploy-vault-dual.yml).

```bash
forge create src/UFOVault.sol:UFOVault \
  --rpc-url https://bsc-dataseed.binance.org \
  --private-key $PRIVATE_KEY \
  --constructor-args \
  <USDT_ADDRESS> \
  <USDC_ADDRESS> \
  <UFO_ADDRESS> \
  <FEE_RECIPIENT_ADDRESS>
```

🛡 Security & Transparency

· Role-Based Access Control: Only the UFOVault contract is granted the MINTER_ROLE and BURNER_ROLE on the UFOToken contract. No arbitrary minting by any external entity is possible.
· Pausable: The contract includes an emergency pause mechanism (controlled by the owner) to protect funds in case of unforeseen vulnerabilities.
· On-Chain Verification: All vault balances, minting activities, and fee distributions are fully verifiable on BscScan.

📄 License

This project is licensed under the MIT License.
<div align="center">
  <h1>🛸 UFO Dollar - Protocol Core</h1>
  <p><strong>A privacy-preserving, dual-collateral, USD-pegged settlement stablecoin on BNB Smart Chain.</strong></p>

  <!-- 这就是“Web3 风格的 CSS”：Shields 徽章 -->
  <p>
    <img src="https://img.shields.io/badge/Network-BNB_Smart_Chain-F3BA2F?style=for-the-badge&logo=binance" alt="Network">
    <img src="https://img.shields.io/badge/Language-Solidity_0.8.20-363636?style=for-the-badge&logo=solidity" alt="Solidity">
    <img src="https://img.shields.io/badge/Framework-Foundry-FF4500?style=for-the-badge" alt="Foundry">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  </p>
</div>

<br />

> **UFO Dollar** is a purpose-built financial infrastructure designed for B2B cross-border trade and institutional fund clearing. It operates without public liquidity pools, ensuring zero slippage and enterprise-grade privacy.

## 🔗 Live Deployments (BSC Mainnet)

| Contract | Address | Status |
| :--- | :--- | :--- |
| **UFOVault** (Core) | [`0x62Eaf08612c77F944265DE421F3Bed054531cC9C`](https://bscscan.com/address/0x62Eaf08612c77F944265DE421F3Bed054531cC9C) | ✅ Active |
| **UFOToken** (ERC20) | [`0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB`](https://bscscan.com/address/0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB) | ✅ Active |

## ✨ Core Architecture

<table>
  <tr>
    <td width="50%">
      <h3>🛡️ Dual-Collateral Resilience</h3>
      <p>Accepts both <b>USDT and USDC</b>. Reserves are tracked independently. If one asset pool is compromised by external forces, the other remains fully operational.</p>
    </td>
    <td width="50%">
      <h3>⚡ Zero-Slippage 1:1 Peg</h3>
      <p>Hardcoded 1:1 peg. No AMM liquidity pools involved. Highly predictable settlement route for institutional traders making large-volume payments.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🔮 Oracle-Free Stability</h3>
      <p>No external price feeds required for minting/redeeming. This entirely eliminates the risk of oracle manipulation or flash-loan attacks.</p>
    </td>
    <td width="50%">
      <h3>🔒 Closed-Loop Privacy</h3>
      <p>Enterprise trade secrets, transaction sizes, and counterparties are shielded from public block explorers and on-chain analysts.</p>
    </td>
  </tr>
</table>

## 🛠 Tech Stack

- **Smart Contracts:** Solidity `^0.8.20`
- **Framework:** Foundry (Forge)
- **Libraries:** OpenZeppelin (ReentrancyGuard, Pausable, AccessControl)
- **CI/CD:** GitHub Actions

<details>
<summary><b>🚀 Click to view Local Development & Testing Guide</b></summary>
<br>

Clone the repository and install dependencies:
<pre><code>git clone https://github.com/ufodollar/bsc-vault.git
cd bsc-vault
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge build
forge test</code></pre>

Create a <code>.env</code> file at the root for deployment:
<pre><code>PRIVATE_KEY=your_wallet_private_key
BSC_RPC_URL=https://bsc-dataseed.binance.org</code></pre>

Deploy to BSC Mainnet:
<pre><code>forge create src/UFOVault.sol:UFOVault --rpc-url $BSC_RPC_URL --private-key $PRIVATE_KEY --constructor-args 0x55d398326f99059fF775485246999027B3197955 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d 0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB &lt;FEE_RECIPIENT_ADDRESS&gt;</code></pre>
</details>

## 🛡 Security

- **RBAC:** Only `UFOVault` holds `MINTER_ROLE` and `BURNER_ROLE`.
- **Pausable:** Emergency halt mechanism for unforeseen vulnerabilities.
- **On-Chain:** All transactions and balances are fully verifiable on BscScan.

<br />

<div align="center">
  <i>This project is licensed under the MIT License.</i>
</div>
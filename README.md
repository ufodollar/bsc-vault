<div align="center">
  <h1>🛸 UFO Dollar - Protocol Core</h1>
  
  <p><strong>The Smart Contract Architecture for the Next-Generation B2B Settlement Stablecoin.</strong></p>
  
  <p>
    <img src="https://img.shields.io/badge/Status-Active-success?style=for-the-badge&logo=checkmarx" alt="Status">
    <img src="https://img.shields.io/badge/Network-BSC_MAINNET-F3BA2F?style=for-the-badge&logo=binance" alt="Network">
    <img src="https://img.shields.io/badge/Solidity-^0.8.20-363636?style=for-the-badge&logo=solidity" alt="Solidity">
    <img src="https://img.shields.io/badge/Framework-Foundry-FF4500?style=for-the-badge" alt="Foundry">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  </p>

  <p>
    <kbd>🚀 Deployment</kbd> &nbsp; • &nbsp; 
    <kbd>✨ Architecture</kbd> &nbsp; • &nbsp; 
    <kbd>🛡️ Security</kbd> &nbsp; • &nbsp; 
    <kbd>📄 License</kbd>
  </p>
</div>

<br />
<hr />

<h2>🔗 Live Deployments (BSC Mainnet)</h2>

<table>
  <thead>
    <tr>
      <th align="left" width="30%">Contract</th>
      <th align="left" width="50%">Address</th>
      <th align="left" width="20%">Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>UFOVault</b> (Dual-Core)</td>
      <td><a href="https://bscscan.com/address/0x62Eaf08612c77F944265DE421F3Bed054531cC9C"><code>0x62Eaf08612c77F944265DE421F3Bed054531cC9C</code></a></td>
      <td>✅ Active</td>
    </tr>
    <tr>
      <td><b>UFOToken</b> (ERC20)</td>
      <td><a href="https://bscscan.com/address/0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB"><code>0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB</code></a></td>
      <td>✅ Active</td>
    </tr>
  </tbody>
</table>

<hr />

<h2>✨ Core Architecture</h2>

<table>
  <tr>
    <td width="50%">
      <h3>🛡️ Multi-Collateral Resilience</h3>
      <p>Accepts both <b>USDT and USDC</b>. Reserves are tracked independently via <code>mapping</code>. If one asset pool is compromised or frozen by external forces, the other remains fully operational, ensuring uninterrupted redemption.</p>
    </td>
    <td width="50%">
      <h3>⚡ Zero-Slippage 1:1 Peg</h3>
      <p>Hardcoded 1:1 peg (1 USDT/USDC = 1 UFO). No AMM liquidity pools involved. Highly predictable settlement route for institutional traders making large-volume cross-border payments.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🔮 Oracle-Free Stability</h3>
      <p>No external price feeds (like Chainlink) required for minting/redeeming. This entirely eliminates the risk of oracle manipulation, flash-loan price attacks, or latency exploits.</p>
    </td>
    <td width="50%">
      <h3>🔒 Closed-Loop Privacy</h3>
      <p>Enterprise trade secrets, transaction sizes, and counterparties are shielded from public block explorers and on-chain analysts, isolating the asset from market speculation.</p>
    </td>
  </tr>
</table>

<hr />

<h2>🛠 Tech Stack</h2>
<ul>
  <li><strong>Smart Contracts:</strong> Solidity <code>^0.8.20</code></li>
  <li><strong>Framework:</strong> Foundry (Forge)</li>
  <li><strong>Libraries:</strong> OpenZeppelin (ReentrancyGuard, Pausable, AccessControl, SafeERC20)</li>
  <li><strong>CI/CD:</strong> GitHub Actions</li>
</ul>

<hr />

<h2>🚀 Local Development & Deployment</h2>

<details>
<summary><b>👉 Click to Expand Deployment Guide</b></summary>
<br>

<b>1. Clone & Install Dependencies</b>
<pre><code class="language-bash">git clone https://github.com/ufodollar/bsc-vault.git
cd bsc-vault
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge build
forge test</code></pre>

<b>2. Environment Variables</b>
<p>Create a <code>.env</code> file at the root for deployment:</p>
<pre><code>PRIVATE_KEY=your_wallet_private_key
BSC_RPC_URL=https://bsc-dataseed.binance.org</code></pre>

<b>3. Deploy to BSC Mainnet</b>
<p><i>Ensure the USDT and USDC addresses are the BEP-20 versions on BSC.</i></p>
<pre><code class="language-bash">forge create src/UFOVault.sol:UFOVault \
  --rpc-url $BSC_RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args \
  0x55d398326f99059fF775485246999027B3197955 \
  0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d \
  0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB \
  &lt;FEE_RECIPIENT_ADDRESS&gt;</code></pre>
</details>

<hr />

<h2>🛡 Security & Transparency</h2>

> ⚠️ **Role-Based Access Control (RBAC)**
> The <code>UFOToken</code> utilizes OpenZeppelin's AccessControl. Only the deployed <code>UFOVault</code> contract is granted the <code>MINTER_ROLE</code> and <code>BURNER_ROLE</code>. No external entity or developer wallet can arbitrarily mint UFO.

> 🛑 **Emergency Pause Mechanism**
> The <code>UFOVault</code> includes a <code>Pausable</code> function controlled by the protocol owner, allowing the team to halt deposits and withdrawals in the event of an unforeseen vulnerability.

> 🔍 **On-Chain Verifiability**
> All vault balances, reserve allocations (USDT vs. USDC), minting activities, and fee distributions are fully transparent and verifiable on BscScan at any time.

<hr />

<h2>📄 License</h2>
<p>This project is licensed under the <b>MIT License</b>.</p>

<br />

<div align="center">
  <img src="https://forthebadge.com/images/badges/built-with-love.svg" height="28">
  <img src="https://forthebadge.com/images/badges/open-source.svg" height="28">
</div>
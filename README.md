<div align="center">
  <h1>🛸 UFO Dollar - Protocol Core</h1>
  <p><strong>The Value-Invisible Stablecoin for Private Commercial Settlement on BNB Chain.</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Status-Active-success?style=for-the-badge&logo=checkmarx" alt="Status">
    <img src="https://img.shields.io/badge/Network-BSC_MAINNET-F3BA2F?style=for-the-badge&logo=binance" alt="Network">
    <img src="https://img.shields.io/badge/Solidity-^0.8.20-363636?style=for-the-badge&logo=solidity" alt="Solidity">
    <img src="https://img.shields.io/badge/Framework-Foundry-FF4500?style=for-the-badge" alt="Foundry">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  </p>
</div>

<br />
<hr />

<h2>🌍 What is UFO Dollar?</h2>
<p><strong>UFO Dollar</strong> is an open-source, USD-pegged stablecoin designed specifically for <b>concealing stablecoin assets and facilitating private commercial settlement</b>. Operating on the BNB Smart Chain, it serves as a powerful financial tool for businesses and individuals who require absolute asset security.</p>

<p>By intentionally avoiding public DEX listings and liquidity pools, mainstream wallets (such as MetaMask and Trust Wallet) display UFO's fiat value as <b>$0.00</b>. This creates a natural "visual camouflage" against physical extortion, extortion, and automated wallet-draining bots. Currently, UFO is widely used in <b>over 60 countries</b> for cryptocurrency security and private commercial settlement.</p>

<p><b>Commercial Use Case:</b> A business can mint UFO using USDT/USDC, transfer it to a commercial partner, and the partner can seamlessly redeem it for stablecoins on the other end—all without drawing public attention or exposing transaction details to on-chain analysts.</p>

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
      <td><b>UFOVault</b> (Core)</td>
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

<h2>✨ Core Architecture</h2>

<table>
  <tr>
    <td width="50%">
      <h3>🕵️ Asset Camouflage ($0 Value)</h3>
      <p>UFO has no public price feeds or DEX pools. Standard wallets display its value as <b>$0.00</b>. This natural camouflage allows for large commercial settlements and payroll transfers without drawing the attention of trackers or malicious actors.</p>
    </td>
    <td width="50%">
      <h3>⚡ Strict 1:1 Peg (Zero Slippage)</h3>
      <p>Mint and redeem at a rigid 1:1 ratio. There are no AMM curves, no liquidity slippage, and no external price oracles to manipulate. What you deposit is exactly what you can withdraw.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🔒 Dual-Collateral</h3>
      <p>Accepts both <b>USDT and USDC</b>. Reserves are tracked independently. If one stablecoin faces regulatory blacklisting, the other pool remains fully operational, ensuring uninterrupted redemption.</p>
    </td>
    <td width="50%">
      <h3>📈 Instant Global Settlement</h3>
      <p>Cross-border funds arrive within seconds. Settlement operates 24/7, bypassing traditional banking delays and enabling seamless private commercial clearing on BSC.</p>
    </td>
  </tr>
</table>

<h2>🛠 Tech Stack</h2>
<ul>
  <li><strong>Smart Contracts:</strong> Solidity <code>^0.8.20</code></li>
  <li><strong>Framework:</strong> Foundry (Forge)</li>
  <li><strong>Libraries:</strong> OpenZeppelin (ReentrancyGuard, Pausable, AccessControl)</li>
</ul>

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

<b>2. Deployment Environment Variables</b>
<p>Create a <code>.env</code> file at the root:</p>
<pre><code>PRIVATE_KEY=your_wallet_private_key
BSC_RPC_URL=https://bsc-dataseed.binance.org</code></pre>

<b>3. Deploy to BSC Mainnet</b>
<pre><code class="language-bash">forge create src/UFOVault.sol:UFOVault \
  --rpc-url $BSC_RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args \
  0x55d398326f99059fF775485246999027B3197955 \
  0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d \
  0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB \
  &lt;FEE_RECIPIENT_ADDRESS&gt;</code></pre>
</details>

<h2>🛡 Security & Transparency</h2>
<blockquote>
  <p>🔍 <strong>On-Chain Verifiability:</strong> While user transactions are camouflaged, the Vault's total reserves are 100% transparent and verifiable on BscScan.</p>
</blockquote>
<blockquote>
  <p>⚠️ <strong>Role-Based Access Control:</strong> Only the <code>UFOVault</code> contract holds the <code>MINTER_ROLE</code> and <code>BURNER_ROLE</code>. No arbitrary minting by any external entity is possible.</p>
</blockquote>

<h2>📄 Legal Disclaimer</h2>
<p><b>This is a technical protocol, not an investment product.</b> UFO does not offer yields or speculative returns. Users and institutional clients are solely responsible for ensuring their use of the protocol complies with local laws. UFO is not offered to persons in restricted jurisdictions including the United States, Mainland China, Iran, North Korea, Syria, Cuba, Venezuela, Russia, and Belarus.</p>

<hr />
<p align="center"><i>This project is licensed under the MIT License.</i></p>
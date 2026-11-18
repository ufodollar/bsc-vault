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

  <p>
    <kbd>🚀 Deployment</kbd> &nbsp; • &nbsp; 
    <kbd>✨ Architecture</kbd> &nbsp; • &nbsp; 
    <kbd>🛡️ Security</kbd> &nbsp; • &nbsp; 
    <kbd>📄 License</kbd>
  </p>
</div>

<br />
<hr />

<h2>🌍 The Value-Invisible Stablecoin</h2>
<blockquote>
  <p><b>Designed for concealing stablecoin assets and private commercial settlement.</b></p>
  <p>UFO Dollar is an open-source, USD-pegged stablecoin. By intentionally avoiding public DEX listings and liquidity pools, mainstream wallets (MetaMask, Trust Wallet) display its fiat value as <b>$0.00</b>. This acts as a natural camouflage against physical extortion, targeted attacks, and automated wallet-draining bots.</p>
  <p>Currently, UFO is widely used in <b>over 60 countries</b> for cryptocurrency security and private commercial settlement. Businesses can mint UFO with USDT/USDC and send it to commercial partners, who seamlessly redeem it for stablecoins—bypassing public exposure and traditional friction.</p>
</blockquote>

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
      <td><a href="https://bscscan.com/address/0xa8A312b008F3EE819C535EB3cAD754B2e5B8b3a2"><code>0xa8A312b008F3EE819C535EB3cAD754B2e5B8b3a2</code></a></td>
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
      <h3>🕵️ Asset Camouflage</h3>
      <p>No public price feeds or DEX pools. Standard wallets display a <b>$0.00</b> value, allowing users to conduct large commercial settlements and payroll transfers without drawing public attention.</p>
    </td>
    <td width="50%">
      <h3>⚡ Strict 1:1 Peg</h3>
      <p>Mint and redeem at a rigid 1:1 ratio. No AMM curves, zero slippage, and no external price oracles to manipulate. What you deposit is exactly what you can withdraw.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🔒 Dual-Collateral</h3>
      <p>Accepts both <b>USDT and USDC</b>. Reserves are strictly isolated. If one stablecoin faces systemic freezing, the other pool remains fully operational for redemption.</p>
    </td>
    <td width="50%">
      <h3>📈 Instant Settlement</h3>
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

<h2>🚀 Local Development &amp; Deployment</h2>
<details>
<summary><b>👉 Click to Expand Deployment Guide</b></summary>
<br>
<b>1. Clone &amp; Install Dependencies</b>
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
  &lt;FEE_RECIPIENT_ADDRESS&gt; \
  0xB97Ad0E74fa7d920791E90258A6E2085088b4320 \
  0xeeF31c7d9F2E82e8A497b140cc60cc082Be4b94e</code></pre>
</details>

<h2>🛡 Security &amp; Transparency</h2>
<blockquote>
  <p>🔍 <strong>On-Chain Verifiability:</strong> While user transaction flows are camouflaged, the Vault's total reserves are 100% transparent and verifiable on BscScan.</p>
</blockquote>
<blockquote>
  <p>⚠️ <strong>Role-Based Access Control:</strong> Only the <code>UFOVault</code> contract holds the <code>MINTER_ROLE</code> and <code>BURNER_ROLE</code>. No arbitrary minting is possible.</p>
</blockquote>

<h2>📄 Legal Disclaimer</h2>
<p><b>This is a technical protocol, not an investment product.</b> UFO does not offer yields or speculative returns. Users are solely responsible for ensuring their use of the protocol complies with local laws. UFO is not offered to persons in restricted jurisdictions including the United States, Mainland China, Iran, North Korea, Syria, Cuba, Venezuela, Russia, and Belarus.</p>

<br />
<div align="center">
  <p><i>This project is licensed under the MIT License.</i></p>
  <img src="https://forthebadge.com/images/badges/built-with-love.svg" height="28">
  <img src="https://forthebadge.com/images/badges/open-source.svg" height="28">
</div>
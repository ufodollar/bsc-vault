<h1>UFO Dollar - Protocol Core & Smart Contracts</h1>

<p>Smart contract architecture for <strong>UFO Dollar</strong>, a dual-collateral, USD-pegged settlement stablecoin on BNB Smart Chain (BSC).</p>

<h2>🔗 Live Deployments (BSC Mainnet)</h2>
<ul>
    <li><strong>UFOVault (Dual-Collateral Core):</strong> <a href="https://bscscan.com/address/0x62Eaf08612c77F944265DE421F3Bed054531cC9C">0x62Eaf08612c77F944265DE421F3Bed054531cC9C</a></li>
    <li><strong>UFOToken (ERC20):</strong> <a href="https://bscscan.com/address/0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB">0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB</a></li>
</ul>

<h2>✨ Core Architecture</h2>
<ul>
    <li><strong>Dual-Collateral:</strong> Accepts both USDT and USDC. Reserves are tracked independently via mapping.</li>
    <li><strong>Zero-Slippage:</strong> Hardcoded 1:1 peg (1 USDT/USDC = 1 UFO). No AMM liquidity pools involved.</li>
    <li><strong>Oracle-Free:</strong> No external price feeds required for minting/redeeming.</li>
    <li><strong>0.5% Protocol Fee:</strong> Applied on both deposit and withdraw.</li>
</ul>

<h2>🛠 Tech Stack</h2>
<ul>
    <li><strong>Smart Contracts:</strong> Solidity ^0.8.20</li>
    <li><strong>Framework:</strong> Foundry (Forge)</li>
    <li><strong>Libraries:</strong> OpenZeppelin (ReentrancyGuard, Pausable, AccessControl)</li>
    <li><strong>CI/CD:</strong> GitHub Actions</li>
</ul>

<h2>🚀 Local Development & Testing</h2>
<pre><code>git clone https://github.com/ufodollar/bsc-vault.git
cd bsc-vault
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge build
forge test</code></pre>

<h3>Environment Variables</h3>
<p>Create a <code>.env</code> file at the root for deployment:</p>
<pre><code>PRIVATE_KEY=your_wallet_private_key
BSC_RPC_URL=https://bsc-dataseed.binance.org</code></pre>

<h3>Deployment to BSC Mainnet</h3>
<pre><code>forge create src/UFOVault.sol:UFOVault --rpc-url $BSC_RPC_URL --private-key $PRIVATE_KEY --constructor-args 0x55d398326f99059fF775485246999027B3197955 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d 0x9CB5e78F88EFfb5315A7B445aFa64790C8e53eaB &lt;FEE_RECIPIENT_ADDRESS&gt;</code></pre>

<h2>🛡 Security</h2>
<ul>
    <li>Only <code>UFOVault</code> holds <code>MINTER_ROLE</code> and <code>BURNER_ROLE</code>.</li>
    <li><code>Pausable</code> mechanism for emergency halts.</li>
    <li>All transactions and balances are fully verifiable on BscScan.</li>
</ul>

<h2>📄 License</h2>
<p>This project is licensed under the MIT License.</p>
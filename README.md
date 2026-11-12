## 🔐 Zero-Knowledge Architecture

Our ZK privacy infrastructure is fully operational. The components are organized as follows:
- `circuits/`: The Circom ZK circuits (e.g., `multiplier.circom`).
- `src/Verifier.sol`: The auto-generated Groth16 smart contract used for on-chain verification.
- `zk-keys/verification_key.json`: The cryptographic verification key generated during the trusted setup. This binds our off-chain proof generation to the on-chain verifier.
- `public/` (in frontend repo): Contains the `.wasm` and `.zkey` files used by the user's browser to generate ZK proofs locally.

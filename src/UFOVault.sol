// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleTree.sol";

// 这是你的 ZK 验证器接口
interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[4] memory input // 现在公开输入是 4 个：root, nullifierHash, recipient, amount
    ) external view returns (bool);
}

contract UFOVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using MerkleTree for MerkleTree.Data;

    IERC20 public immutable usdt;
    IVerifier public immutable verifier;
    MerkleTree.Data public tree;

    // 面额管理：防止隐藏金额导致的计算溢出，采用固定面额（如 10, 100, 1000）
    mapping(uint256 => bool) public allowedAmounts;
    
    // 防双花记录
    mapping(uint256 => bool) public nullifierHashes;

    event Deposit(uint256 indexed commitment, uint32 leafIndex);
    event Withdraw(address indexed recipient, uint256 indexed nullifierHash);

    constructor(address _usdt, address _verifier) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        verifier = IVerifier(_verifier);
        // 初始化树根
        tree.root = 0; 
        // 预设面额
        allowedAmounts[10 * 1e18] = true;
        allowedAmounts[100 * 1e18] = true;
        allowedAmounts[1000 * 1e18] = true;
    }

    /**
     * @dev 隐私存款 (隐藏是谁存的)
     * @param commitment 前端算好的暗号哈希
     * @param amount 存款金额 (必须在白名单内)
     */
    function deposit(uint256 commitment, uint256 amount) external nonReentrant {
        require(allowedAmounts[amount], "Invalid amount");
        
        // 将真实的 USDT 吸入金库
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        
        // 将暗号插入默克尔树
        uint256 newRoot = tree.insert(commitment);
        
        emit Deposit(commitment, tree.nextIndex - 1);
    }

    /**
     * @dev 隐私提款 (隐藏提给谁)
     * 此时代币将由 UFO 转换为真实的 USDT
     */
    function withdraw(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint256 root,
        uint256 nullifierHash,
        address payable recipient,
        uint256 amount
    ) external nonReentrant {
        // 1. 检查根合法性
        require(tree.root == root, "Invalid Merkle Root");

        // 2. 检查是否双花
        require(!nullifierHashes[nullifierHash], "Note already spent");

        // 3. 验证 ZK 证明
        // 注意：这里的 input 顺序必须和 Circom 电路中的公开信号顺序严格一致
        uint[4] memory input = [root, nullifierHash, uint256(uint160(recipient)), amount];
        bool isValid = verifier.verifyProof(a, b, c, input);
        require(isValid, "Invalid ZK Proof");

        // 4. 标记作废并转账
        nullifierHashes[nullifierHash] = true;
        usdt.safeTransfer(recipient, amount);

        emit Withdraw(recipient, nullifierHash);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUFOToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract UFOVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    IUFOToken public immutable ufo;
    
    // 🌟 1:1 比例，不再需要 RATE 变量，直接 1 比 1 兑换
    
    address public FEE_RECIPIENT;
    uint256 public constant FEE_RATE = 50; // 0.5%
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount);

    constructor(address _usdt, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
        FEE_RECIPIENT = _feeRecipient;
    }

    // 用 USDT 买 UFO (1:1)
    function deposit(uint256 usdtAmount) external nonReentrant {
        require(usdtAmount > 0, "Amount must be > 0");
        
        // 1. 计算手续费 (0.5%)
        uint256 feeAmount = (usdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = usdtAmount - feeAmount;

        // 2. 1:1 映射，净 USDT 就是 UFO 数量
        uint256 ufoAmount = netUsdtAmount;
        require(ufoAmount > 0, "Amount too small");

        // 3. 把手续费直接打给 Main 钱包
        if (feeAmount > 0) {
            usdt.safeTransferFrom(msg.sender, FEE_RECIPIENT, feeAmount);
        }
        
        // 4. 把剩下的 USDT 放进金库，并给用户铸造 UFO
        usdt.safeTransferFrom(msg.sender, address(this), netUsdtAmount);
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(msg.sender, netUsdtAmount, ufoAmount);
    }

    // 用 UFO 赎回 USDT (1:1)
    function withdraw(uint256 ufoAmount) external nonReentrant {
        require(ufoAmount > 0, "Amount must be > 0");

        // 1. 1:1 映射，UFO 数量就是毛 USDT 数量
        uint256 grossUsdtAmount = ufoAmount;

        // 2. 计算手续费 (0.5%)
        uint256 feeAmount = (grossUsdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = grossUsdtAmount - feeAmount;

        // 3. 销毁用户的 UFO
        ufo.burn(msg.sender, ufoAmount);

        // 4. 把手续费打给 Main 钱包，剩下的还给用户
        if (feeAmount > 0) {
            usdt.safeTransfer(FEE_RECIPIENT, feeAmount);
        }
        usdt.safeTransfer(msg.sender, netUsdtAmount);

        emit Withdrawn(msg.sender, ufoAmount, netUsdtAmount);
    }

    // 🌟 前端调用获取实时汇率（固定返回 1 * 10^18，代表 1:1）
    function getExchangeRate() external pure returns (uint256) {
        return 1 * 10**18; 
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        FEE_RECIPIENT = _newRecipient;
    }
}
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
    
    // 汇率: 1 UFO = 10 USDT
    uint256 public constant RATE = 10; 
    
    // 🔥 核心新增：手续费接收钱包和费率 (50 代表 0.5%，分母是 10000)
    address public FEE_RECIPIENT;
    uint256 public constant FEE_RATE = 50; 
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount);

    // 🔥 部署时传入 USDT地址、UFO地址、你的MAIN钱包地址
    constructor(address _usdt, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
        FEE_RECIPIENT = _feeRecipient;
    }

    // 用 USDT 买 UFO
    function deposit(uint256 usdtAmount) external nonReentrant {
        require(usdtAmount > 0, "Amount must be > 0");
        
        // 1. 计算手续费 (0.5%)
        uint256 feeAmount = (usdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = usdtAmount - feeAmount;

        // 2. 计算能换多少 UFO (基于扣除手续费后的净 USDT)
        uint256 ufoAmount = netUsdtAmount / RATE;
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

    // 用 UFO 赎回 USDT
    function withdraw(uint256 ufoAmount) external nonReentrant {
        require(ufoAmount > 0, "Amount must be > 0");

        // 1. 计算总共能换出多少 USDT
        uint256 grossUsdtAmount = ufoAmount * RATE;

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

    // 前端调用获取实时汇率
    function getExchangeRate() external pure returns (uint256) {
        return RATE; 
    }

    // 允许 Owner 修改手续费接收地址（万一以后要换钱包）
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        FEE_RECIPIENT = _newRecipient;
    }
}
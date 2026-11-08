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
    
    uint256 public constant RATE = 10; // 1 UFO = 10 USDT
    address public FEE_RECIPIENT;
    uint256 public constant FEE_RATE = 50; // 0.5%
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount);

    // 构造函数现在接收三个参数：USDT地址、UFO地址、手续费接收地址
    constructor(address _usdt, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
        FEE_RECIPIENT = _feeRecipient;
    }

    function deposit(uint256 usdtAmount) external nonReentrant {
        require(usdtAmount > 0, "Amount must be > 0");
        
        uint256 feeAmount = (usdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = usdtAmount - feeAmount;
        uint256 ufoAmount = netUsdtAmount / RATE;
        require(ufoAmount > 0, "Amount too small");

        if (feeAmount > 0) {
            usdt.safeTransferFrom(msg.sender, FEE_RECIPIENT, feeAmount);
        }
        usdt.safeTransferFrom(msg.sender, address(this), netUsdtAmount);
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(msg.sender, netUsdtAmount, ufoAmount);
    }

    function withdraw(uint256 ufoAmount) external nonReentrant {
        require(ufoAmount > 0, "Amount must be > 0");

        uint256 grossUsdtAmount = ufoAmount * RATE;
        uint256 feeAmount = (grossUsdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = grossUsdtAmount - feeAmount;

        ufo.burn(msg.sender, ufoAmount);

        if (feeAmount > 0) {
            usdt.safeTransfer(FEE_RECIPIENT, feeAmount);
        }
        usdt.safeTransfer(msg.sender, netUsdtAmount);

        emit Withdrawn(msg.sender, ufoAmount, netUsdtAmount);
    }

    function getExchangeRate() external pure returns (uint256) {
        return RATE; 
    }
}
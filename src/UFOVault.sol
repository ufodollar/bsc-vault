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
    
    // BSC 上 USDT 精度是 18 位，UFO 也是 18 位
    // 设定 1 UFO = 10 USDT
    uint256 public constant RATE = 10; 

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount);

    constructor(address _usdt, address _ufo) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
    }

    // 用 USDT 换 UFO
    function deposit(uint256 usdtAmount) external nonReentrant {
        require(usdtAmount > 0, "Amount must be > 0");
        
        // 假设精度都是 18，所以直接除 RATE
        uint256 ufoAmount = usdtAmount / RATE;
        require(ufoAmount > 0, "Amount too small");

        usdt.safeTransferFrom(msg.sender, address(this), usdtAmount);
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(msg.sender, usdtAmount, ufoAmount);
    }

    // 用 UFO 换回 USDT
    function withdraw(uint256 ufoAmount) external nonReentrant {
        require(ufoAmount > 0, "Amount must be > 0");

        uint256 usdtAmount = ufoAmount * RATE;

        ufo.burn(msg.sender, ufoAmount);
        usdt.safeTransfer(msg.sender, usdtAmount);

        emit Withdrawn(msg.sender, ufoAmount, usdtAmount);
    }

    // 前端读取汇率
    function getExchangeRate() external pure returns (uint256) {
        return RATE;
    }

    // 紧急提款（仅限管理员）
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
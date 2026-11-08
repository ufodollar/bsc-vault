// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IUFOToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract UFOVault is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    IUFOToken public immutable ufo;

    address public feeRecipient;
    
    uint256 public constant FEE_RATE = 50; 
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount, uint256 feeAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount, uint256 feeAmount);

    error ZeroAddress();
    error ZeroAmount();
    error AmountTooSmall();

    constructor(address _usdt, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        if (_usdt == address(0) || _ufo == address(0) || _feeRecipient == address(0)) revert ZeroAddress();
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
        feeRecipient = _feeRecipient;
    }

    function deposit(uint256 usdtAmount) external nonReentrant whenNotPaused {
        if (usdtAmount == 0) revert ZeroAmount();

        uint256 feeAmount = (usdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = usdtAmount - feeAmount;
        uint256 ufoAmount = netUsdtAmount;
        
        if (ufoAmount == 0) revert AmountTooSmall();

        if (feeAmount > 0) {
            usdt.safeTransferFrom(msg.sender, feeRecipient, feeAmount);
        }
        usdt.safeTransferFrom(msg.sender, address(this), netUsdtAmount);
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(msg.sender, netUsdtAmount, ufoAmount, feeAmount);
    }

    function withdraw(uint256 ufoAmount) external nonReentrant whenNotPaused {
        if (ufoAmount == 0) revert ZeroAmount();

        uint256 grossUsdtAmount = ufoAmount;
        uint256 feeAmount = (grossUsdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = grossUsdtAmount - feeAmount;

        // 销毁用户的 UFO，不需要用户对 UFO 做 approve
        ufo.burn(msg.sender, ufoAmount);

        if (feeAmount > 0) {
            usdt.safeTransfer(feeRecipient, feeAmount);
        }
        usdt.safeTransfer(msg.sender, netUsdtAmount);

        emit Withdrawn(msg.sender, ufoAmount, netUsdtAmount, feeAmount);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddress();
        feeRecipient = _newRecipient;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function getExchangeRate() external pure returns (uint256) {
        return 1 * 10**18; 
    }
}
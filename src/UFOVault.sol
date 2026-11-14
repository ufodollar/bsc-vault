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

    IUFOToken public immutable ufo;
    address public feeRecipient;

    // 多抵押品支持：记录哪些代币被允许作为储备金
    mapping(address => bool) public isSupportedToken;
    // 记录每种代币（USDT/USDC）的独立储备量，实现风险隔离
    mapping(address => uint256) public totalReserves;

    // 0.5% 结算费
    uint256 public constant FEE_RATE = 50; 
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 ufoAmount, uint256 feeAmount);
    event Withdrawn(address indexed user, address indexed token, uint256 ufoAmount, uint256 amount, uint256 feeAmount);

    error UnsupportedToken();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientLiquidity();

    constructor(address _usdt, address _usdc, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        if (_usdt == address(0) || _usdc == address(0) || _ufo == address(0) || _feeRecipient == address(0)) revert ZeroAddress();
        
        ufo = IUFOToken(_ufo);
        feeRecipient = _feeRecipient;
        
        // 初始化支持的稳定币
        isSupportedToken[_usdt] = true;
        isSupportedToken[_usdc] = true;
    }

    /**
     * @dev 存入 USDT 或 USDC 铸造 UFO（在此处收取 0.5% 手续费）
     * @param tokenAddress 支付使用的稳定币地址 (USDT 或 USDC)
     * @param amount 支付金额
     */
    function deposit(address tokenAddress, uint256 amount) external nonReentrant whenNotPaused {
        if (!isSupportedToken[tokenAddress]) revert UnsupportedToken();
        if (amount == 0) revert ZeroAmount();

        uint256 feeAmount = (amount * FEE_RATE) / FEE_BASE;
        uint256 netAmount = amount - feeAmount;
        
        IERC20 token = IERC20(tokenAddress);

        // 1. 扣除手续费
        if (feeAmount > 0) {
            token.safeTransferFrom(msg.sender, feeRecipient, feeAmount);
        }
        // 2. 净额存入独立金库
        token.safeTransferFrom(msg.sender, address(this), netAmount);
        
        // 3. 增加该代币的独立储备量
        totalReserves[tokenAddress] += netAmount;

        // 4. 铸造等额 UFO 给用户 (1 UFO ≈ 1 USD)
        ufo.mint(msg.sender, netAmount);

        emit Deposited(msg.sender, tokenAddress, netAmount, netAmount, feeAmount);
    }

    /**
     * @dev 销毁 UFO 赎回对应的 USDT 或 USDC（在此处收取 0.5% 手续费）
     * 遵循“同币种进出”原则，保证金库绝对安全
     */
    function withdraw(address tokenAddress, uint256 ufoAmount) external nonReentrant whenNotPaused {
        if (!isSupportedToken[tokenAddress]) revert UnsupportedToken();
        if (ufoAmount == 0) revert ZeroAmount();

        uint256 feeAmount = (ufoAmount * FEE_RATE) / FEE_BASE;
        uint256 netAmount = ufoAmount - feeAmount;

        // 确保当前代币池子有足够的流动性
        if (totalReserves[tokenAddress] < netAmount) revert InsufficientLiquidity();

        // 1. 销毁用户的 UFO
        ufo.burn(msg.sender, ufoAmount);

        // 2. 减少该代币储备
        totalReserves[tokenAddress] -= netAmount;

        IERC20 token = IERC20(tokenAddress);
        
        // 3. 扣除手续费给平台
        if (feeAmount > 0) {
            token.safeTransfer(feeRecipient, feeAmount);
        }
        // 4. 净额退还给用户
        token.safeTransfer(msg.sender, netAmount);

        emit Withdrawn(msg.sender, tokenAddress, ufoAmount, netAmount, feeAmount);
    }

    function addSupportedToken(address _token) external onlyOwner {
        isSupportedToken[_token] = true;
    }

    function removeSupportedToken(address _token) external onlyOwner {
        isSupportedToken[_token] = false;
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
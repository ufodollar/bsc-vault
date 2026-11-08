// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
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
    
    // 0.5% 手续费
    uint256 public constant FEE_RATE = 50; 
    uint256 public constant FEE_BASE = 10000;

    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoAmount, uint256 feeAmount);
    event Withdrawn(address indexed user, uint256 ufoAmount, uint256 usdtAmount, uint256 feeAmount);
    event FeeRecipientUpdated(address indexed newRecipient);

    // 自定义错误，减少 Gas 并让报错更清晰
    error ZeroAddress();
    error ZeroAmount();
    error AmountTooSmall();

    constructor(address _usdt, address _ufo, address _feeRecipient) Ownable(msg.sender) {
        if (_usdt == address(0) || _ufo == address(0) || _feeRecipient == address(0)) {
            revert ZeroAddress();
        }
        
        usdt = IERC20(_usdt);
        ufo = IUFOToken(_ufo);
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice 用户存入 USDT，1:1 获得 UFO
     * @dev 用户必须提前对金库合约 approve 足够的 USDT
     */
    function deposit(uint256 usdtAmount) external nonReentrant whenNotPaused {
        if (usdtAmount == 0) revert ZeroAmount();

        // 1. 计算 0.5% 手续费
        uint256 feeAmount = (usdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = usdtAmount - feeAmount;

        // 2. 1:1 映射，净 USDT 就是应得的 UFO
        uint256 ufoAmount = netUsdtAmount;
        if (ufoAmount == 0) revert AmountTooSmall();

        // 3. 安全拉取：直接从用户钱包扣除手续费给收款方，扣除本金给金库
        // 这里依靠的是用户在前端执行的 approve(VAULT_ADDRESS, usdtAmount)
        if (feeAmount > 0) {
            usdt.safeTransferFrom(msg.sender, feeRecipient, feeAmount);
        }
        usdt.safeTransferFrom(msg.sender, address(this), netUsdtAmount);

        // 4. 调用 UFO 合约的 mint 方法给用户铸造代币
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(msg.sender, netUsdtAmount, ufoAmount, feeAmount);
    }

    /**
     * @notice 用户销毁 UFO，1:1 赎回 USDT
     * @dev 用户不需要对 UFO 进行 approve，金库利用 BURNER_ROLE 直接销毁用户的 UFO
     */
    function withdraw(uint256 ufoAmount) external nonReentrant whenNotPaused {
        if (ufoAmount == 0) revert ZeroAmount();

        // 1. 1:1 映射
        uint256 grossUsdtAmount = ufoAmount;
        if (grossUsdtAmount == 0) revert AmountTooSmall();

        // 2. 计算手续费
        uint256 feeAmount = (grossUsdtAmount * FEE_RATE) / FEE_BASE;
        uint256 netUsdtAmount = grossUsdtAmount - feeAmount;

        // 3. 销毁用户的 UFO （金库必须有足够的 BURNER_ROLE）
        ufo.burn(msg.sender, ufoAmount);

        // 4. 金库把 USDT 打给用户，把手续费打给收款方
        if (feeAmount > 0) {
            usdt.safeTransfer(feeRecipient, feeAmount);
        }
        usdt.safeTransfer(msg.sender, netUsdtAmount);

        emit Withdrawn(msg.sender, ufoAmount, netUsdtAmount, feeAmount);
    }

    // --- 管理职能 ---

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddress();
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // 供前端调用
    function getExchangeRate() external pure returns (uint256) {
        return 1 * 10**18; 
    }
}
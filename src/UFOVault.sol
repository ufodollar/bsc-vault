// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UFO Fund Vault (Institutional Grade)
 * @notice A flexible yield-bearing vault on BSC, integrated with Aave V3.
 * @dev Deposits USDT into Aave, mints UFO shares, and charges a 1.5% redemption fee.
 */

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IUFOToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract UFOVault {
    // ==========================================
    // 核心常量配置 (BSC 主网)
    // ==========================================
    IERC20 public constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IAavePool public constant AAVE_POOL = IAavePool(0x6807dc923806fE8Fd134338EABCA509979a7e0cB);
    IERC20 public constant aToken = IERC20(0xa9251ca9DE909CB71783723713B21E4233fbf1B1);
    
    // 平台利润接收地址 (部署时会由 GitHub Actions 自动替换为真实的 Main 钱包)
    address public constant PROFIT_RECIPIENT = 0x0000000000000000000000000000000000000000;

    // 赎回手续费 1.5% (基数 10000，150 即代表 0.015)
    uint256 public constant WITHDRAW_FEE_PERCENT = 150; 

    // ==========================================
    // 状态变量
    // ==========================================
    IUFOToken public immutable ufoToken;
    uint256 private _status = 1;

    // ==========================================
    // 事件 (Events) - 机构级必备
    // ==========================================
    event Deposited(address indexed user, uint256 usdtAmount, uint256 ufoMinted);
    event Withdrawn(address indexed user, uint256 ufoBurned, uint256 usdtReturned, uint256 feePaid);

    // ==========================================
    // 修饰器
    // ==========================================
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    constructor(address _ufoToken) {
        require(_ufoToken != address(0), "Invalid token address");
        ufoToken = IUFOToken(_ufoToken);
        // 授权 Aave 无上限动用金库中的 USDT
        USDT.approve(address(AAVE_POOL), type(uint256).max);
    }

    // ==========================================
    // 核心视图函数
    // ==========================================

    /**
     * @notice 获取实时净值 (NAV)
     * @dev NAV 包含 18 位精度。aToken 为 6 位精度，需转为 18 位。
     */
    function getExchangeRate() public view returns (uint256) {
        uint256 totalSupply = ufoToken.totalSupply();
        if (totalSupply == 0) return 1e18; 
        
        uint256 totalAssets = aToken.balanceOf(address(this));
        // (6位精度的总资产 * 1e12 变成 18位) * 1e18 / 18位的总份额
        return (totalAssets * 1e12 * 1e18) / totalSupply;
    }

    // ==========================================
    // 用户交互函数
    // ==========================================

    /**
     * @notice 随时申购 (Deposit)
     * @param _amount 用户存入的 USDT 数量 (6 位精度)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        bool isFirstDeposit = (ufoToken.totalSupply() == 0);

        // 1. 将 USDT 从用户钱包拉到金库
        USDT.transferFrom(msg.sender, address(this), _amount);
        
        // 2. 将 USDT 存入 Aave V3
        AAVE_POOL.supply(address(USDT), _amount, address(this), 0);
        
        // 3. 计算可铸造的 UFO 数量
        uint256 nav = getExchangeRate();
        uint256 ufoAmount = (_amount * 1e12 * 1e18) / nav;
        
        // 4. 🛡️ 机构级安全：防初始净值通胀攻击 (Inflation Attack)
        if (isFirstDeposit) {
            // 铸造极小额的"死份额"（1000 wei）发送至黑洞地址，永久锁死。
            // 防止黑客利用极小金额存钱，随后暴力转账拉高 NAV 来窃取后续用户本金。
            uint256 deadShares = 1000;
            ufoToken.mint(address(0x000000000000000000000000000000000000dEaD), deadShares);
            ufoAmount = ufoAmount - deadShares;
        }

        require(ufoAmount > 0, "UFO amount too small");
        
        // 5. 给用户铸造份额
        ufoToken.mint(msg.sender, ufoAmount);
        
        emit Deposited(msg.sender, _amount, ufoAmount);
    }

    /**
     * @notice 随时赎回 (Redeem) - 扣除 1.5% 手续费
     * @param _ufoAmount 用户销毁的 UFO 数量 (18 位精度)
     */
    function withdraw(uint256 _ufoAmount) external nonReentrant {
        require(_ufoAmount > 0, "UFO amount must be greater than 0");

        // 1. 计算用户能拿到的总 USDT 金额
        uint256 nav = getExchangeRate();
        uint256 usdtAmount = (_ufoAmount * nav) / 1e18 / 1e12;
        require(usdtAmount > 0, "USDT amount too small");

        // 2. 计算 1.5% 的手续费及用户实际到手金额
        uint256 feeAmount = (usdtAmount * WITHDRAW_FEE_PERCENT) / 10000;
        uint256 userAmount = usdtAmount - feeAmount;
        
        // 3. 🔥 物理销毁用户的 UFO 份额
        ufoToken.burn(msg.sender, _ufoAmount);
        
        // 4. 从 Aave 提取总额
        uint256 actualWithdrawn = AAVE_POOL.withdraw(address(USDT), usdtAmount, address(this));
        
        // 5. 资金分配：手续费打入你的 Main 钱包，剩下打给用户
        if (feeAmount > 0) {
            USDT.transfer(PROFIT_RECIPIENT, feeAmount);
        }
        
        // 🔥 防极端情况：如果 Aave 提取的金额比计算少，则把实际提现的余额全部给用户，保障平台安全。
        if (actualWithdrawn < usdtAmount) {
            USDT.transfer(msg.sender, actualWithdrawn - feeAmount);
        } else {
            USDT.transfer(msg.sender, userAmount);
        }
        
        emit Withdrawn(msg.sender, _ufoAmount, userAmount, feeAmount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    IERC20 public constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IAavePool public constant AAVE_POOL = IAavePool(0x6807dc923806fE8Fd134338EABCA509979a7e0cB);
    IERC20 public constant aToken = IERC20(0xa9251ca9DE909CB71783723713B21E4233fbf1B1);
    
    // 手续费接收地址（部署脚本会在部署时自动替换为你真实的 Main 钱包地址）
    address public constant PROFIT_RECIPIENT = 0x0000000000000000000000000000000000000000;

    // 🔥 赎回手续费 1.5% (150 / 10000 = 0.015)
    uint256 public constant WITHDRAW_FEE_PERCENT = 150; 

    IUFOToken public immutable ufoToken;
    uint256 private _status = 1;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    constructor(address _ufoToken) {
        ufoToken = IUFOToken(_ufoToken);
        USDT.approve(address(AAVE_POOL), type(uint256).max);
    }

    // 净值 = 金库总资产（包含所有利息） / UFO总流通量
    function getExchangeRate() public view returns (uint256) {
        uint256 totalSupply = ufoToken.totalSupply();
        if (totalSupply == 0) return 1e18; 
        uint256 totalAssets = aToken.balanceOf(address(this));
        return (totalAssets * 1e12 * 1e18) / totalSupply;
    }

    // 🔥 随时申购（无时间限制）
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        bool isFirstDeposit = (ufoToken.totalSupply() == 0);

        // 1. 拉取 USDT 并存入 Aave
        USDT.transferFrom(msg.sender, address(this), _amount);
        AAVE_POOL.supply(address(USDT), _amount, address(this), 0);
        
        // 2. 计算并铸造 UFO
        uint256 nav = getExchangeRate();
        uint256 ufoAmount = (_amount * 1e12 * 1e18) / nav;
        
        // 3. 🛡️ 机构级安全：防初始净值通胀攻击 (Inflation Attack)
        if (isFirstDeposit) {
            ufoToken.mint(address(0x000000000000000000000000000000000000dEaD), 1000);
            ufoAmount = ufoAmount - 1000;
        }

        require(ufoAmount > 0, "UFO amount too small");
        ufoToken.mint(msg.sender, ufoAmount);
    }

    // 🔥 随时赎回（仅扣除 1.5% 手续费）
    function withdraw(uint256 _ufoAmount) external nonReentrant {
        require(_ufoAmount > 0, "UFO amount must be greater than 0");

        // 1. 计算总资产价值
        uint256 nav = getExchangeRate();
        uint256 usdtAmount = (_ufoAmount * nav) / 1e18 / 1e12;
        require(usdtAmount > 0, "USDT amount too small");

        // 2. 计算 1.5% 手续费
        uint256 feeAmount = (usdtAmount * WITHDRAW_FEE_PERCENT) / 10000;
        uint256 userAmount = usdtAmount - feeAmount;
        
        // 3. 销毁用户的 UFO 份额
        ufoToken.burn(msg.sender, _ufoAmount);
        
        // 4. 从 Aave 提取总额
        AAVE_POOL.withdraw(address(USDT), usdtAmount, address(this));
        
        // 5. 分配资金：手续费直接打给 Main 钱包，本金+利息打给用户
        if (feeAmount > 0) {
            USDT.transfer(PROFIT_RECIPIENT, feeAmount);
        }
        USDT.transfer(msg.sender, userAmount);
    }
}

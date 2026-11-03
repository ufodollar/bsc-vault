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
    
    // 利润接收地址（部署脚本或手动部署时替换为真实的 Main 钱包地址）
    address public constant PROFIT_RECIPIENT = 0x0000000000000000000000000000000000000000;

    IUFOToken public immutable ufoToken;
    uint256 public lastHarvestBalance;
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

    function getExchangeRate() public view returns (uint256) {
        uint256 totalSupply = ufoToken.totalSupply();
        if (totalSupply == 0) return 1e18; 
        uint256 totalAssets = aToken.balanceOf(address(this));
        return (totalAssets * 1e12 * 1e18) / totalSupply;
    }

    function _isJanuary() internal view returns (bool) {
        // 东八区（UTC+8）时间计算
        uint256 timestamp = block.timestamp + 8 hours;
        uint256 year = timestamp / 365 days;
        uint256 yearStart = year * 365 days;
        uint256 dayOfYear = (timestamp - yearStart) / 1 days;
        
        // 1月1日到1月31日（dayOfYear 为 0 到 30）
        return dayOfYear <= 30;
    }

    modifier redeemSeason() {
        require(_isJanuary(), "Redeem is only allowed in January");
        _;
    }

    // 🔥 彻底移除 depositSeason 限制，全年随时可存！
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        bool isFirstDeposit = (ufoToken.totalSupply() == 0);

        USDT.transferFrom(msg.sender, address(this), _amount);
        AAVE_POOL.supply(address(USDT), _amount, address(this), 0);
        
        uint256 nav = getExchangeRate();
        uint256 ufoAmount = (_amount * 1e12 * 1e18) / nav;
        
        // 🛡️ 防初始净值通胀攻击 (Inflation Attack)
        if (isFirstDeposit) {
            ufoToken.mint(address(0x000000000000000000000000000000000000dEaD), 1000);
            ufoAmount = ufoAmount - 1000;
        }

        require(ufoAmount > 0, "UFO amount too small");
        
        ufoToken.mint(msg.sender, ufoAmount);
        lastHarvestBalance += _amount;
    }

    function withdraw(uint256 _ufoAmount) external nonReentrant redeemSeason {
        require(_ufoAmount > 0, "UFO amount must be greater than 0");
        
        _harvestProfitInternal();

        uint256 nav = getExchangeRate();
        uint256 usdtAmount = (_ufoAmount * nav) / 1e18 / 1e12;
        require(usdtAmount > 0, "USDT amount too small");
        
        ufoToken.burn(msg.sender, _ufoAmount);
        
        uint256 actualWithdrawn = AAVE_POOL.withdraw(address(USDT), usdtAmount, address(this));
        USDT.transfer(msg.sender, actualWithdrawn);
        
        lastHarvestBalance -= actualWithdrawn;
    }

    function harvestProfit() external nonReentrant {
        _harvestProfitInternal();
    }

    function _harvestProfitInternal() internal {
        uint256 currentBalance = aToken.balanceOf(address(this));
        if (currentBalance <= lastHarvestBalance) return;
        
        uint256 profit = currentBalance - lastHarvestBalance;
        uint256 platformProfit = profit / 2;
        
        if (platformProfit > 0) {
            AAVE_POOL.withdraw(address(USDT), platformProfit, PROFIT_RECIPIENT);
            lastHarvestBalance = currentBalance - platformProfit;
        }
    }
}

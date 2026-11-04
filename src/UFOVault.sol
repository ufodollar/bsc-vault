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
    
    // 利润接收地址（部署脚本会自动替换）
    address public constant PROFIT_RECIPIENT = 0x0000000000000000000000000000000000000000;

    // 赎回手续费 0.1% (10 / 10000 = 0.1%)
    uint256 public constant WITHDRAW_FEE_PERCENT = 10; 

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

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        bool isFirstDeposit = (ufoToken.totalSupply() == 0);

        USDT.transferFrom(msg.sender, address(this), _amount);
        AAVE_POOL.supply(address(USDT), _amount, address(this), 0);
        
        uint256 nav = getExchangeRate();
        uint256 ufoAmount = (_amount * 1e12 * 1e18) / nav;
        
        if (isFirstDeposit) {
            ufoToken.mint(address(0x000000000000000000000000000000000000dEaD), 1000);
            ufoAmount = ufoAmount - 1000;
        }

        require(ufoAmount > 0, "UFO amount too small");
        ufoToken.mint(msg.sender, ufoAmount);
        lastHarvestBalance += _amount;
    }

    function withdraw(uint256 _ufoAmount) external nonReentrant {
        require(_ufoAmount > 0, "UFO amount must be greater than 0");
        
        // 1. 结算平台未提取的 50% 利润
        _harvestProfitInternal();

        // 2. 计算用户应得的总金额（包含本金+利息）
        uint256 nav = getExchangeRate();
        uint256 usdtAmount = (_ufoAmount * nav) / 1e18 / 1e12;
        require(usdtAmount > 0, "USDT amount too small");

        // 3. 🔥 计算 0.1% 赎回手续费，并算出用户实际到手的金额
        uint256 feeAmount = (usdtAmount * WITHDRAW_FEE_PERCENT) / 10000;
        uint256 userAmount = usdtAmount - feeAmount;
        
        // 4. 销毁用户的 UFO
        ufoToken.burn(msg.sender, _ufoAmount);
        
        // 5. 从 Aave 提取总金额
        uint256 actualWithdrawn = AAVE_POOL.withdraw(address(USDT), usdtAmount, address(this));
        
        // 6. 分配资金：手续费给平台，剩下给用户
        if (feeAmount > 0) {
            USDT.transfer(PROFIT_RECIPIENT, feeAmount);
        }
        USDT.transfer(msg.sender, userAmount);
        
        // 7. 更新台账（本金扣除已提走的用户金额+手续费）
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

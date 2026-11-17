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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title UFOVault
 * @notice UFO 刚性锚定 USD，但不刚性锚定 USDT/USDC。
 *         存入/赎回均按 Chainlink 实时 USD 价格换算 UFO 和稳定币数量，
 *         手续费按 USD 价值收取，防止稳定币脱锚期间的跨币种套利。
 */
contract UFOVault is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ---------- 常量 ----------
    uint256 public constant FEE_RATE = 50;              // 0.5%
    uint256 public constant FEE_BASE = 10000;
    uint256 public constant PRICE_DECIMALS = 1e18;       // 内部价格统一 18 位精度
    uint256 public constant MAX_PRICE_DEVIATION = 200;   // 2%（基点，10000 = 100%）
    uint256 public constant MAX_PRICE_STALENESS = 3600;  // 1 小时

    // ---------- 不可变状态 ----------
    IUFOToken public immutable ufo;
    address public feeRecipient;

    // ---------- 价格源与储备 ----------
    mapping(address => bool) public isSupportedToken;
    mapping(address => uint256) public totalReserves;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    address[] public supportedTokens;

    // ---------- 事件 ----------
    event Deposited(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 ufoAmount,
        uint256 feeAmount
    );
    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 ufoAmount,
        uint256 amount,
        uint256 feeAmount
    );
    event PriceFeedUpdated(address indexed token, address indexed newFeed);

    // ---------- 错误 ----------
    error UnsupportedToken();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientLiquidity();
    error StalePrice();
    error InvalidPrice();
    error PriceDeviationTooHigh();
    error PriceFeedNotSet();
    error InvalidFeeRecipient();

    constructor(
        address _usdt,
        address _usdc,
        address _ufo,
        address _feeRecipient,
        address _usdtPriceFeed,
        address _usdcPriceFeed
    ) Ownable(msg.sender) {
        if (
            _usdt == address(0) ||
            _usdc == address(0) ||
            _ufo == address(0) ||
            _feeRecipient == address(0) ||
            _usdtPriceFeed == address(0) ||
            _usdcPriceFeed == address(0)
        ) revert ZeroAddress();
        if (_feeRecipient == address(this)) revert InvalidFeeRecipient();

        ufo = IUFOToken(_ufo);
        feeRecipient = _feeRecipient;

        isSupportedToken[_usdt] = true;
        supportedTokens.push(_usdt);
        priceFeeds[_usdt] = AggregatorV3Interface(_usdtPriceFeed);

        isSupportedToken[_usdc] = true;
        supportedTokens.push(_usdc);
        priceFeeds[_usdc] = AggregatorV3Interface(_usdcPriceFeed);
    }

    // =====================================================================
    //                          价格读取
    // =====================================================================

    /**
     * @notice 读取 Chainlink 价格，返回 18 位精度的 USD 价格。
     *         校验：answer > 0、未 stale、answeredInRound >= roundId、偏离 $1 不超过 2%。
     */
    function getPrice(address tokenAddress) public view returns (uint256) {
        AggregatorV3Interface feed = priceFeeds[tokenAddress];
        if (address(feed) == address(0)) revert PriceFeedNotSet();

        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = feed.latestRoundData();

        if (answer <= 0) revert InvalidPrice();
        if (updatedAt == 0 || updatedAt > block.timestamp) revert StalePrice();
        if (block.timestamp - updatedAt > MAX_PRICE_STALENESS) revert StalePrice();
        if (answeredInRound < roundId) revert StalePrice();

        uint8 feedDecimals = feed.decimals();
        uint256 price18 = uint256(answer);
        if (feedDecimals < 18) {
            price18 *= 10 ** (18 - feedDecimals);
        } else if (feedDecimals > 18) {
            price18 /= 10 ** (feedDecimals - 18);
        }

        // 偏离熔断：稳定币价格偏离 $1 超过 2% 时拒绝交易
        uint256 deviation = price18 > PRICE_DECIMALS
            ? price18 - PRICE_DECIMALS
            : PRICE_DECIMALS - price18;
        if ((deviation * FEE_BASE) / PRICE_DECIMALS > MAX_PRICE_DEVIATION) {
            revert PriceDeviationTooHigh();
        }

        return price18;
    }

    // =====================================================================
    //                          存入 / 赎回
    // =====================================================================

    /**
     * @notice 存入 USDT 或 USDC，按实时 USD 价值铸造 UFO。
     *         手续费按 USD 价值计算，以 token 数量转给 feeRecipient。
     */
    function deposit(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (!isSupportedToken[tokenAddress]) revert UnsupportedToken();
        if (amount == 0) revert ZeroAmount();

        uint256 price = getPrice(tokenAddress);
        uint256 usdValue = (amount * price) / PRICE_DECIMALS;
        if (usdValue == 0) revert ZeroAmount();

        uint256 feeUsd = (usdValue * FEE_RATE) / FEE_BASE;
        uint256 feeTokens = (feeUsd * PRICE_DECIMALS) / price;
        uint256 netTokens = amount - feeTokens;

        IERC20 token = IERC20(tokenAddress);
        if (feeTokens > 0) {
            token.safeTransferFrom(msg.sender, feeRecipient, feeTokens);
        }
        token.safeTransferFrom(msg.sender, address(this), netTokens);

        totalReserves[tokenAddress] += netTokens;

        uint256 ufoAmount = usdValue - feeUsd;
        ufo.mint(msg.sender, ufoAmount);

        emit Deposited(
            msg.sender,
            tokenAddress,
            amount,
            ufoAmount,
            feeTokens
        );
    }

    /**
     * @notice 销毁 UFO，按实时 USD 价值赎回选定稳定币。
     *         手续费按 USD 价值计算，以稳定币形式转给 feeRecipient。
     */
    function withdraw(
        address tokenAddress,
        uint256 ufoAmount
    ) external nonReentrant whenNotPaused {
        if (!isSupportedToken[tokenAddress]) revert UnsupportedToken();
        if (ufoAmount == 0) revert ZeroAmount();

        uint256 price = getPrice(tokenAddress);
        uint256 usdValue = ufoAmount;
        uint256 feeUsd = (usdValue * FEE_RATE) / FEE_BASE;
        uint256 netUsd = usdValue - feeUsd;

        uint256 tokenOut = (netUsd * PRICE_DECIMALS) / price;
        if (tokenOut == 0) revert ZeroAmount();

        uint256 feeTokens = (feeUsd * PRICE_DECIMALS) / price;
        uint256 totalOut = tokenOut + feeTokens;

        if (totalReserves[tokenAddress] < totalOut) {
            revert InsufficientLiquidity();
        }

        ufo.burn(msg.sender, ufoAmount);
        totalReserves[tokenAddress] -= totalOut;

        IERC20 token = IERC20(tokenAddress);
        if (feeTokens > 0) {
            token.safeTransfer(feeRecipient, feeTokens);
        }
        token.safeTransfer(msg.sender, tokenOut);

        emit Withdrawn(
            msg.sender,
            tokenAddress,
            ufoAmount,
            tokenOut,
            feeTokens
        );
    }

    // =====================================================================
    //                          NAV / 管理
    // =====================================================================

    /**
     * @notice 基于链上储备 USD 价值与 UFO 总供应量计算 NAV。
     */
    function getExchangeRate() external view returns (uint256) {
        uint256 supply = ufo.totalSupply();
        if (supply == 0) return PRICE_DECIMALS;

        uint256 totalUsdValue;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 reserve = totalReserves[token];
            if (reserve == 0) continue;

            AggregatorV3Interface feed = priceFeeds[token];
            if (address(feed) == address(0)) continue;

            (
                uint80 roundId,
                int256 answer,
                ,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = feed.latestRoundData();

            if (answer <= 0) continue;
            if (updatedAt == 0 || updatedAt > block.timestamp) continue;
            if (block.timestamp - updatedAt > MAX_PRICE_STALENESS) continue;
            if (answeredInRound < roundId) continue;

            uint8 fd = feed.decimals();
            uint256 p18 = uint256(answer);
            if (fd < 18) {
                p18 *= 10 ** (18 - fd);
            } else if (fd > 18) {
                p18 /= 10 ** (fd - 18);
            }

            totalUsdValue += (reserve * p18) / PRICE_DECIMALS;
        }

        uint256 nav = (totalUsdValue * PRICE_DECIMALS) / supply;
        return nav > PRICE_DECIMALS ? PRICE_DECIMALS : nav;
    }

    // =====================================================================
    //                          管理函数
    // =====================================================================

    function addSupportedToken(
        address _token,
        address _priceFeed
    ) external onlyOwner {
        if (_token == address(0) || _priceFeed == address(0)) {
            revert ZeroAddress();
        }
        if (!isSupportedToken[_token]) {
            isSupportedToken[_token] = true;
            supportedTokens.push(_token);
        }
        priceFeeds[_token] = AggregatorV3Interface(_priceFeed);
        emit PriceFeedUpdated(_token, _priceFeed);
    }

    // 🚨 修复点：移除代币前强制要求储备金清空
    function removeSupportedToken(address _token) external onlyOwner {
        if (totalReserves[_token] > 0) revert InsufficientLiquidity();
        
        isSupportedToken[_token] = false;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _token) {
                supportedTokens[i] = supportedTokens[supportedTokens.length - 1];
                supportedTokens.pop();
                break;
            }
        }
    }

    function setPriceFeed(address _token, address _newFeed) external onlyOwner {
        if (_token == address(0) || _newFeed == address(0)) {
            revert ZeroAddress();
        }
        priceFeeds[_token] = AggregatorV3Interface(_newFeed);
        emit PriceFeedUpdated(_token, _newFeed);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddress();
        if (_newRecipient == address(this)) revert InvalidFeeRecipient();
        feeRecipient = _newRecipient;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
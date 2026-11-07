// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UFOToken.sol";
import "../src/UFOVault.sol";

// 模拟一个简单的 USDT 用于测试
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockUSDT is ERC20 {
    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract UFOVaultTest is Test {
    UFOToken public ufo;
    UFOVault public vault;
    MockUSDT public usdt;

    address public user = address(0x1);

    function setUp() public {
        ufo = new UFOToken();
        usdt = new MockUSDT();
        vault = new UFOVault(address(usdt), address(ufo));

        // 授权 Vault 可以 mint 和 burn
        ufo.grantRole(ufo.MINTER_ROLE(), address(vault));
        ufo.grantRole(ufo.BURNER_ROLE(), address(vault));

        // 给测试用户转点 USDT
        usdt.transfer(user, 1000 * 10**18);
    }

    function test_Deposit() public {
        vm.startPrank(user);
        usdt.approve(address(vault), 100 * 10**18);
        
        // 存 100 USDT，应该得到 10 UFO
        vault.deposit(100 * 10**18);
        
        assertEq(ufo.balanceOf(user), 10 * 10**18);
        vm.stopPrank();
    }

    function test_Withdraw() public {
        // 先存
        vm.startPrank(user);
        usdt.approve(address(vault), 100 * 10**18);
        vault.deposit(100 * 10**18);
        
        // 再取 10 UFO，应该换回 100 USDT
        vault.withdraw(10 * 10**18);
        assertEq(usdt.balanceOf(user), 1000 * 10**18); 
        vm.stopPrank();
    }
}
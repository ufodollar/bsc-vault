// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UFOToken.sol";
import "../src/UFOVault.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // BSC 主网 USDT 地址
        address usdtAddress = 0x55d398326f99059fF775485246999027B3197955; 

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 UFO 代币
        UFOToken ufo = new UFOToken();
        
        // 2. 部署金库
        UFOVault vault = new UFOVault(usdtAddress, address(ufo));

        // 3. 授予金库 Mint 和 Burn 权限
        ufo.grantRole(ufo.MINTER_ROLE(), address(vault));
        ufo.grantRole(ufo.BURNER_ROLE(), address(vault));

        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UFOToken.sol";
import "../src/UFOVault.sol";

contract DeployScript is Script {
    function run() external {
        // 从 GitHub Secrets 注入的环境变量中读取
        uint256 deployerPrivateKey = vm.envUint("MAIN_PRIVATE_KEY");
        address mainAddr = vm.envAddress("MAIN_WALLET_ADDRESS");
        
        // BSC 主网上的 USDT 地址
        address usdtAddress = 0x55d398326f99059fF775485246999027B3197955; 

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Fee Recipient (Main):", mainAddr);

        // 1. 部署 UFO 代币
        UFOToken ufo = new UFOToken();
        console.log("UFOToken deployed at:", address(ufo));
        
        // 2. 部署金库 (带手续费接收地址)
        UFOVault vault = new UFOVault(usdtAddress, address(ufo), mainAddr);
        console.log("UFOVault deployed at:", address(vault));

        // 3. 授予金库合约 Mint 和 Burn 权限
        ufo.grantRole(ufo.MINTER_ROLE(), address(vault));
        ufo.grantRole(ufo.BURNER_ROLE(), address(vault));
        console.log("Roles granted to Vault!");

        vm.stopBroadcast();
    }
}
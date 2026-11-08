// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UFOToken.sol";
import "../src/UFOVault.sol";

contract DeployScript is Script {
    function run() external {
        // 🔥 核心修复：这里的名字必须和 deploy.yml 里配置的环境变量名一致
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address mainAddr = vm.envAddress("MAIN_ADDR");
        
        // BSC 主网上的 USDT 地址
        address usdtAddress = 0x55d398326f99059fF775485246999027B3197955; 

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Fee Recipient:", mainAddr);

        // 1. 部署 UFO 代币
        UFOToken ufo = new UFOToken();
        console.log("UFOToken deployed at:", address(ufo));
        
        // 2. 部署金库 (1:1 比例，传入 usdt、ufo、main钱包)
        UFOVault vault = new UFOVault(usdtAddress, address(ufo), mainAddr);
        console.log("UFOVault deployed at:", address(vault));

        // 3. 自动授予金库合约 Mint 和 Burn 权限
        ufo.grantRole(ufo.MINTER_ROLE(), address(vault));
        ufo.grantRole(ufo.BURNER_ROLE(), address(vault));
        console.log("Roles granted to Vault!");

        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UFOToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("UFO Dollar", "UFO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // 只有拥有 MINTER_ROLE 的地址（即金库合约）才能铸造 UFO
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // 只有拥有 BURNER_ROLE 的地址（即金库合约）才能销毁 UFO
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MerkleTree {
    uint32 public constant TREE_DEPTH = 20; // 树的高度，可容纳 100万+ 笔存款

    struct Data {
        uint256 root;
        uint256[TREE_DEPTH] filledSubtrees;
        uint32 nextIndex;
        mapping(uint256 => bool) branches; // 记录走过的分叉，用于更新 root
    }

    function insert(Data storage self, uint256 leaf) internal returns (uint256) {
        require(self.nextIndex < 2**TREE_DEPTH, "Tree is full");
        uint32 currentIndex = self.nextIndex;
        uint256 currentHash = leaf;

        for (uint32 i = 0; i < TREE_DEPTH; i++) {
            if (currentIndex % 2 == 0) {
                self.filledSubtrees[i] = currentHash;
                currentHash = hashLeftRight(currentHash, 0);
            } else {
                currentHash = hashLeftRight(self.filledSubtrees[i], currentHash);
            }
            currentIndex /= 2;
        }

        self.root = currentHash;
        self.nextIndex++;
        return self.root;
    }

    function hashLeftRight(uint256 left, uint256 right) internal pure returns (uint256) {
        // 在真实生产环境中，这里必须调用 Poseidon 哈希的合约实现，
        // 而不是 keccak256，因为电路里用的是 Poseidon
        return uint256(keccak256(abi.encodePacked(left, right)));
    }
}
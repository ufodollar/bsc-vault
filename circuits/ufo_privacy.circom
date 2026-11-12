pragma circom 2.0.0;

// 引入官方的 Poseidon 哈希库 (Actions会自动下载)
include "../circomlib/circuits/poseidon.circom";

template UFOPrivacy() {
    // 私有输入（企业自己知道，不上链）
    signal input amount;
    signal input secret;

    // 公开输入（上链供验证）
    signal output commitment;    // 承诺哈希 (代表这笔钱)
    signal output nullifier;     // 作废符 (防双花)

    // 1. 计算承诺：commitment = Hash(amount, secret)
    component hashCommitment = Poseidon(2);
    hashCommitment.inputs[0] <== amount;
    hashCommitment.inputs[1] <== secret;
    commitment <== hashCommitment.out;

    // 2. 计算防双花标识：nullifier = Hash(commitment, secret)
    component hashNullifier = Poseidon(2);
    hashNullifier.inputs[0] <== commitment;
    hashNullifier.inputs[1] <== secret;
    nullifier <== hashNullifier.out;
}

component main = UFOPrivacy();
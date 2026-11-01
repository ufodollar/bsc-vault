#!/bin/bash
cd ~/bsc-vault || exit 1
echo "=========================================="
echo "🚀 UFO Fund 全自动部署脚本"
echo "=========================================="
echo -e "\n[1/6] 正在生成新钱包..."
INFO=$(cast wallet new)
ADDR=$(echo "$INFO" | grep -oE '0x[a-fA-F0-9]{40}' | head -n 1)
PK=$(echo "$INFO" | grep -oE '0x[a-fA-F0-9]{64}' | head -n 1)

if [ -z "$ADDR" ] || [ -z "$PK" ]; then
    echo "❌ 获取地址或私钥失败！"; exit 1
fi

echo -e "\n[2/6] ✅ 钱包生成成功！"
echo "------------------------------------------"
echo "💰 请向此地址充值约 0.003 BNB (BSC网络):"
echo -e "\033[1;32m$ADDR\033[0m"
echo "------------------------------------------"
echo "🔑 私钥 (已静默保存至 .env.deployer):"
echo -e "\033[1;31m$PK\033[0m"
echo "⚠️ 请务必自己复制并妥善保存私钥！"
echo "------------------------------------------"

echo "👉 充值到账后，按 [Enter] 键继续..."
read -p "" -n 1 -s -r

echo -e "\n[3/6] 正在将利润接收地址设为你的新钱包..."
sed -i "s|address public constant PROFIT_RECIPIENT = .*;|address public constant PROFIT_RECIPIENT = $ADDR;|g" src/UFOVault.sol

echo -e "\n[4/6] 正在部署全新 UFO 代币..."
OUT1=$(forge create src/UFOToken.sol:UFOToken --private-key $PK --rpc-url https://bsc-rpc.publicnode.com --broadcast --chain-id 56 --legacy --gas-price 1gwei 2>&1)
TOKEN=$(echo "$OUT1" | grep -oE '0x[a-fA-F0-9]{40}' | head -n 1)
if [ -z "$TOKEN" ]; then echo "❌ 代币部署失败！"; echo "$OUT1"; exit 1; fi
echo "✅ 代币地址: $TOKEN"

echo -e "\n[5/6] 正在部署全新 UFO 金库..."
OUT2=$(forge create src/UFOVault.sol:UFOVault --constructor-args $TOKEN --private-key $PK --rpc-url https://bsc-rpc.publicnode.com --broadcast --chain-id 56 --legacy --gas-price 1gwei 2>&1)
VAULT=$(echo "$OUT2" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)
if [ -z "$VAULT" ]; then echo "❌ 金库部署失败！"; echo "$OUT2"; exit 1; fi
echo "✅ 金库地址: $VAULT"

echo -e "\n[6/6] 正在授权铸币权，执行闭环..."
OUT3=$(cast send $TOKEN "setMinter(address,bool)" $VAULT true --private-key $PK --rpc-url https://bsc-rpc.publicnode.com --legacy --gas-price 1gwei 2>&1)
if [[ "$OUT3" == *"status               1"* ]]; then
    echo "✅ 授权成功，合约已彻底闭环！"
else
    echo "❌ 授权失败！"; echo "$OUT3"; exit 1
fi

echo -e "\n=========================================="
echo "🎉 部署大满贯！全流程已闭环！"
echo "新代币地址: $TOKEN"
echo "新金库地址: $VAULT"
echo "=========================================="
echo "💡 下一步: 请使用下面的地址去更新你的前端！"

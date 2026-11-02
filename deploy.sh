#!/bin/bash
set -e

# ================== 颜色定义 ==================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN} 🚀 UFO Fund 工业级部署引擎 (阅后即焚版)${NC}"
echo -e "${CYAN}==================================================${NC}"

# ================== 环境检查 ==================
if ! command -v forge &> /dev/null || ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Foundry (forge/cast)。请先安装。${NC}"
    exit 1
fi

if [ ! -f "src/UFOToken.sol" ] || [ ! -f "src/UFOVault.sol" ]; then
    echo -e "${RED}❌ 错误: 找不到合约文件，请确保在 ~/bsc-vault 目录下运行。${NC}"
    exit 1
fi

# ================== 1. 生成双钱包 ==================
echo -e "\n${YELLOW}[1/4] 正在生成双钱包架构...${NC}"

# 生成 Main 钱包
MAIN_INFO=$(cast wallet new)
MAIN_ADDR=$(echo "$MAIN_INFO" | grep "Address:" | awk '{print $NF}')
MAIN_PK=$(echo "$MAIN_INFO" | grep "Private key:" | awk '{print $NF}')

# 生成 Branch 钱包
BRANCH_INFO=$(cast wallet new)
BRANCH_ADDR=$(echo "$BRANCH_INFO" | grep "Address:" | awk '{print $NF}')
BRANCH_PK=$(echo "$BRANCH_INFO" | grep "Private key:" | awk '{print $NF}')

if [ -z "$MAIN_ADDR" ] || [ -z "$BRANCH_ADDR" ]; then
    echo -e "${RED}❌ 错误: 钱包生成失败。${NC}"
    exit 1
fi

# ================== 2. 配套展示钱包，等待记录 ==================
echo -e "\n${RED}🚨 请立刻抄写以下私钥！按下回车后，本屏幕将被清空且无法恢复！🚨${NC}"
echo -e "${CYAN}==================================================${NC}"

echo -e "${YELLOW}👑 【Main 钱包】(大老板：部署、拥有合约、收利润)${NC}"
echo -e "   地址: ${GREEN}${MAIN_ADDR}${NC}"
echo -e "   私钥: ${RED}${MAIN_PK}${NC}"

echo -e "${CYAN}==================================================${NC}"

echo -e "${YELLOW}🛠️ 【Branch 钱包】(打工人：付 Gas 跑 Cloudflare 定时任务)${NC}"
echo -e "   地址: ${GREEN}${BRANCH_ADDR}${NC}"
echo -e "   私钥: ${RED}${BRANCH_PK}${NC}"

echo -e "${CYAN}==================================================${NC}"

echo -e "\n${YELLOW}👉 充值提示：${NC}"
echo -e "   1. 向 ${GREEN}Main 钱包${NC} 充入 0.003 BNB (部署用)"
echo -e "   2. 向 ${GREEN}Branch 钱包${NC} 充入 0.005 BNB (Gas用)"

# 关键节点：等待用户按下回车
read -p "👉 确认已经记好私钥并完成充值后，请按 [Enter] 键继续..."

# ================== 3. 物理焚毁敏感信息 ==================
# 1. 清空屏幕
clear
# 2. 抹除磁盘历史
if [ -f ~/.bash_history ]; then > ~/.bash_history; fi
# 3. 抹除内存历史
history -c 2>/dev/null || true

echo -e "${GREEN}✅ 屏幕与终端历史已彻底清理。私钥已隐蔽，开始执行上链部署...${NC}"
echo -e "${CYAN}==================================================${NC}"

# ================== 4. 部署执行 ==================
RPC="https://bsc-rpc.publicnode.com"
GAS="1gwei"

echo -e "\n${YELLOW}[2/4] 正在使用 Main 钱包部署 UFO 代币...${NC}"
OUT1=$(forge create src/UFOToken.sol:UFOToken --private-key $MAIN_PK --rpc-url $RPC --broadcast --chain-id 56 --legacy --gas-price $GAS 2>&1)
TOKEN=$(echo "$OUT1" | grep 'Deployed to:' | awk '{print $NF}')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ 错误: UFO 代币部署失败，请检查 Main 钱包 BNB 余额是否充足。${NC}"
    echo -e "${RED}--- 详细报错信息 ---${NC}"
    echo "$OUT1"
    exit 1
fi
echo -e "${GREEN}✅ 代币部署成功: $TOKEN${NC}"

echo -e "\n${YELLOW}[3/4] 正在使用 Main 钱包部署 UFO 金库...${NC}"
# 自动替换利润地址
sed -i "s|address public constant PROFIT_RECIPIENT = .*;|address public constant PROFIT_RECIPIENT = $MAIN_ADDR;|g" src/UFOVault.sol
OUT2=$(forge create src/UFOVault.sol:UFOVault --constructor-args $TOKEN --private-key $MAIN_PK --rpc-url $RPC --broadcast --chain-id 56 --legacy --gas-price $GAS 2>&1)
VAULT=$(echo "$OUT2" | grep 'Deployed to:' | awk '{print $NF}')

if [ -z "$VAULT" ]; then
    echo -e "${RED}❌ 错误: 金库部署失败！${NC}"
    echo -e "${RED}--- 详细报错信息 ---${NC}"
    echo "$OUT2"
    exit 1
fi
echo -e "${GREEN}✅ 金库部署成功: $VAULT${NC}"

echo -e "\n${YELLOW}[4/4] 正在为新金库授权 UFO 铸币权...${NC}"
OUT3=$(cast send $TOKEN "setMinter(address,bool)" $VAULT true --private-key $MAIN_PK --rpc-url $RPC --legacy --gas-price $GAS 2>&1)

if [[ "$OUT3" == *"status               1"* ]]; then
    echo -e "${GREEN}✅ 授权成功！全流程闭环。${NC}"
else
    echo -e "${RED}❌ 授权失败！${NC}"
    echo -e "${RED}--- 详细报错信息 ---${NC}"
    echo "$OUT3"
    exit 1
fi

# ================== 5. 最终输出结果 ==================
echo -e "\n${CYAN}==================================================${NC}"
echo -e "${GREEN}🎉 部署大满贯！工业级流水线已全部闭环！${NC}"
echo -e "${CYAN}==================================================${NC}"

# 此时屏幕上只会打印公开的地址结果
echo -e "\n${YELLOW}📋 【公开地址备忘录】 (请截图或复制)：${NC}"
echo -e "新代币地址 (UFO): ${GREEN}$TOKEN${NC}"
echo -e "新金库地址 (Vault): ${GREEN}$VAULT${NC}"

echo -e "\n${YELLOW}🛠️ 【后续操作提示】：${NC}"
echo -e "1. 去前端代码 App.jsx 替换上述两个地址。"
echo -e "2. 去 Cloudflare 环境变量填入选定的 Branch 私钥。"
echo -e "${CYAN}==================================================${NC}"

# ================== 6. 内存销毁 ==================
# 销毁内存中的敏感变量
unset MAIN_PK
unset BRANCH_PK
unset MAIN_INFO
unset BRANCH_INFO

# 正常退出，保留终端界面
exit 0

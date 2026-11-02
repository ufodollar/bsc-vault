#!/bin/bash
set +e  # 强制关闭所有错误静默退出机制，保证能看到任何报错

# ================== 颜色定义 ==================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN} 🚀 UFO Fund 部署引擎 (BSC 主网真实版)${NC}"
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

MAIN_INFO=$(cast wallet new)
MAIN_ADDR=$(echo "$MAIN_INFO" | grep -oE '0x[a-fA-F0-9]{40}' | head -n 1)
MAIN_PK=$(echo "$MAIN_INFO" | grep -oE '0x[a-fA-F0-9]{64}' | head -n 1)

BRANCH_INFO=$(cast wallet new)
BRANCH_ADDR=$(echo "$BRANCH_INFO" | grep -oE '0x[a-fA-F0-9]{40}' | head -n 1)
BRANCH_PK=$(echo "$BRANCH_INFO" | grep -oE '0x[a-fA-F0-9]{64}' | head -n 1)

if [ -z "$MAIN_ADDR" ] || [ -z "$BRANCH_ADDR" ]; then
    echo -e "${RED}❌ 错误: 钱包生成失败。${NC}"
    exit 1
fi

# ================== 2. 展示并等待充值 ==================
echo -e "\n${RED}🚨 请立刻抄写以下私钥！按下回车后，屏幕将被清空且无法恢复！🚨${NC}"
echo -e "${CYAN}==================================================${NC}"

echo -e "${YELLOW}👑 【Main 钱包】(大老板：部署、拥有合约、收利润)${NC}"
echo -e "   地址: ${GREEN}${MAIN_ADDR}${NC}"
echo -e "   私钥: ${RED}${MAIN_PK}${NC}"

echo -e "${CYAN}==================================================${NC}"

echo -e "${YELLOW}🛠️ 【Branch 钱包】(打工人：付 Gas 跑 Cloudflare 定时任务)${NC}"
echo -e "   地址: ${GREEN}${BRANCH_ADDR}${NC}"
echo -e "   私钥: ${RED}${BRANCH_PK}${NC}"

echo -e "${CYAN}==================================================${NC}"

echo -e "\n${YELLOW}👉 ⚠️ 真实主网充值提示：${NC}"
echo -e "   1. 向 ${GREEN}Main 钱包 (${MAIN_ADDR})${NC} 转入 0.003 BNB"
echo -e "   2. 向 ${GREEN}Branch 钱包 (${BRANCH_ADDR})${NC} 转入 0.005 BNB"

echo -e "\n${CYAN}==================================================${NC}"
read -p "👉 确认 BNB 已真实到账，且私钥已保存后，按 [Enter] 键开始主网部署..."

# ================== 3. 物理焚毁敏感信息 ==================
printf '\033c'
if [ -f ~/.bash_history ]; then > ~/.bash_history; fi
history -c 2>/dev/null || true

echo -e "${GREEN}✅ 屏幕与终端历史已彻底清理，开始向 BSC 主网广播交易...${NC}"
echo -e "${CYAN}==================================================${NC}"

# ================== 4. 部署执行 (BSC 主网) ==================
RPC="https://bsc-rpc.publicnode.com"
GAS="1gwei"

echo -e "\n[2/4] 正在使用 Main 钱包部署 UFO 代币...${NC}"
OUT1=$(forge create src/UFOToken.sol:UFOToken --private-key $MAIN_PK --rpc-url $RPC --broadcast --chain-id 56 --legacy --gas-price $GAS 2>&1)
EXIT1=$?
TOKEN=$(echo "$OUT1" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)

if [ $EXIT1 -ne 0 ] || [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ 错误: 代币部署失败！以下是真实报错日志：${NC}"
    echo -e "${RED}--------------------------------------------------${NC}"
    echo "$OUT1"
    echo -e "${RED}--------------------------------------------------${NC}"
    echo -e "${YELLOW}💡 提示：如果看到 'insufficient funds'，说明你还没往 Main 钱包充真实的 BNB。${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 代币部署成功: $TOKEN${NC}"

echo -e "\n[3/4] 正在使用 Main 钱包部署 UFO 金库...${NC}"
sed -i "s|address public constant PROFIT_RECIPIENT = .*;|address public constant PROFIT_RECIPIENT = $MAIN_ADDR;|g" src/UFOVault.sol
OUT2=$(forge create src/UFOVault.sol:UFOVault --constructor-args $TOKEN --private-key $MAIN_PK --rpc-url $RPC --broadcast --chain-id 56 --legacy --gas-price $GAS 2>&1)
EXIT2=$?
VAULT=$(echo "$OUT2" | grep -oE '0x[a-fA-F0-9]{40}' | tail -n 1)

if [ $EXIT2 -ne 0 ] || [ -z "$VAULT" ]; then
    echo -e "${RED}❌ 错误: 金库部署失败！以下是真实报错日志：${NC}"
    echo -e "${RED}--------------------------------------------------${NC}"
    echo "$OUT2"
    echo -e "${RED}--------------------------------------------------${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 金库部署成功: $VAULT${NC}"

echo -e "\n[4/4] 正在为新金库授权 UFO 铸币权...${NC}"
OUT3=$(cast send $TOKEN "setMinter(address,bool)" $VAULT true --private-key $MAIN_PK --rpc-url $RPC --legacy --gas-price $GAS 2>&1)
EXIT3=$?

if [[ "$OUT3" == *"status               1"* ]]; then
    echo -e "${GREEN}✅ 授权成功！全流程闭环。${NC}"
else
    echo -e "${RED}❌ 授权失败！以下是真实报错日志：${NC}"
    echo -e "${RED}--------------------------------------------------${NC}"
    echo "$OUT3"
    echo -e "${RED}--------------------------------------------------${NC}"
    exit 1
fi

# ================== 5. 最终输出结果 ==================
echo -e "\n${CYAN}==================================================${NC}"
echo -e "${GREEN}🎉 恭喜！BSC 主网合约部署大满贯！${NC}"
echo -e "${CYAN}==================================================${NC}"

echo -e "\n${YELLOW}📋 【核心地址备忘录】 (请截图或复制)：${NC}"
echo -e "新代币地址 (UFO): ${GREEN}$TOKEN${NC}"
echo -e "新金库地址 (Vault): ${GREEN}$VAULT${NC}"

echo -e "\n${YELLOW}🛠️ 【后续操作提示】：${NC}"
echo -e "1. 去前端代码 App.jsx 替换上述两个地址。"
echo -e "2. 去 Cloudflare 环境变量填入 Branch 私钥。"
echo -e "3. 去 GitHub 的 ufo-harvester 仓库更新 worker.js 里的金库地址。"
echo -e "${CYAN}==================================================${NC}"

unset MAIN_PK
unset BRANCH_PK
unset MAIN_INFO
unset BRANCH_INFO

exit 0

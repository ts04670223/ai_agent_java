#!/bin/bash
# Kubernetes Dashboard 卸載腳本

set -e

echo "========================================="
echo "Kubernetes Dashboard 卸載程序"
echo "========================================="

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 確認卸載
echo -e "${YELLOW}警告: 即將卸載 Kubernetes Dashboard${NC}"
echo -e "是否繼續? (y/N)"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "已取消卸載"
    exit 0
fi

echo -e "\n${YELLOW}[1/3] 刪除管理員用戶...${NC}"
kubectl delete serviceaccount admin-user -n kubernetes-dashboard 2>/dev/null || true
kubectl delete clusterrolebinding admin-user 2>/dev/null || true
echo -e "${GREEN}✓ 管理員用戶已刪除${NC}"

echo -e "\n${YELLOW}[2/3] 卸載 Dashboard...${NC}"
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml 2>/dev/null || true
echo -e "${GREEN}✓ Dashboard 已卸載${NC}"

echo -e "\n${YELLOW}[3/3] 清理令牌文件...${NC}"
rm -f /vagrant/k8s-dashboard/dashboard-token.txt
echo -e "${GREEN}✓ 令牌文件已刪除${NC}"

echo -e "\n${GREEN}========================================="
echo "Kubernetes Dashboard 卸載完成！"
echo "=========================================${NC}"

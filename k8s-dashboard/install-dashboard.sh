#!/bin/bash
# Kubernetes Dashboard 安裝腳本
# 適用於 Ubuntu 20.04 + Kubernetes

set -e

echo "========================================="
echo "Kubernetes Dashboard 安裝程序"
echo "========================================="

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 檢查是否為 root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}錯誤: 此腳本必須以 root 權限執行${NC}"
   echo "請使用: sudo $0"
   exit 1
fi

# 檢查 kubectl 是否安裝
echo -e "${YELLOW}[1/6] 檢查 kubectl...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}錯誤: kubectl 未安裝${NC}"
    echo "請先安裝 Kubernetes"
    exit 1
fi

echo -e "${GREEN}✓ kubectl 已安裝${NC}"
kubectl version --client

# 檢查 Kubernetes 集群狀態
echo -e "\n${YELLOW}[2/6] 檢查 Kubernetes 集群狀態...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}錯誤: 無法連接到 Kubernetes 集群${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes 集群運行正常${NC}"
kubectl get nodes

# 安裝 Kubernetes Dashboard
echo -e "\n${YELLOW}[3/6] 安裝 Kubernetes Dashboard...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo -e "${GREEN}✓ Dashboard 部署配置已應用${NC}"

# 等待 Dashboard Pod 啟動
echo -e "\n${YELLOW}[4/6] 等待 Dashboard Pod 啟動...${NC}"
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=300s

echo -e "${GREEN}✓ Dashboard Pod 已就緒${NC}"

# 創建管理員用戶
echo -e "\n${YELLOW}[5/6] 創建管理員用戶...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

echo -e "${GREEN}✓ 管理員用戶已創建${NC}"

# 生成訪問令牌
echo -e "\n${YELLOW}[6/6] 生成訪問令牌...${NC}"
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=87600h)

# 保存令牌到文件
TOKEN_FILE="/vagrant/k8s-dashboard/dashboard-token.txt"
echo "$TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo -e "${GREEN}✓ 訪問令牌已生成並保存到: $TOKEN_FILE${NC}"

# 顯示訪問信息
echo -e "\n${GREEN}========================================="
echo "Kubernetes Dashboard 安裝完成！"
echo "=========================================${NC}"
echo ""
echo -e "${YELLOW}訪問方式：${NC}"
echo "1. 在 VM 中啟動 kubectl proxy："
echo "   kubectl proxy --address='0.0.0.0' --accept-hosts='.*'"
echo ""
echo "2. 在 Windows 瀏覽器訪問："
echo "   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo -e "${YELLOW}登入令牌（Token）：${NC}"
echo "$TOKEN"
echo ""
echo -e "${YELLOW}令牌已保存到：${NC}"
echo "$TOKEN_FILE"
echo ""
echo -e "${YELLOW}查看 Dashboard 狀態：${NC}"
echo "kubectl get pods -n kubernetes-dashboard"
echo ""
echo -e "${GREEN}安裝完成！${NC}"

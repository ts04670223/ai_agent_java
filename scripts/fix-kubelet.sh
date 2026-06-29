#!/bin/bash
# 修復 kubelet hostname-override 問題
# 原因：VM hostname 從 k8s-master 改為 k8s-test-new，但 K8s 節點仍註冊為 k8s-master

echo "=== 修復 kubelet hostname-override ==="

# 1. 覆寫 kubelet flags
echo 'KUBELET_KUBEADM_ARGS="--hostname-override=k8s-master --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9"' \
  | sudo tee /var/lib/kubelet/kubeadm-flags.env

# 2. 建立 subnet.env（/run 是 tmpfs，重啟後消失）
sudo mkdir -p /run/flannel
sudo tee /run/flannel/subnet.env > /dev/null << 'EOF'
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF
echo "✓ subnet.env 已建立"

# 3. 重啟 kubelet
sudo systemctl restart kubelet
echo "✓ kubelet 已重啟"

# 4. 等待 Node Ready
echo "等待 Node 變為 Ready..."
for i in $(seq 1 12); do
  STATUS=$(kubectl get node k8s-master -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  if [ "$STATUS" = "True" ]; then
    echo "✓ Node k8s-master 已 Ready！"
    kubectl get nodes
    exit 0
  fi
  echo "  等待中... ($i/12)"
  sleep 5
done

echo "⚠ Node 仍未 Ready，檢查 kubelet 日誌："
sudo journalctl -u kubelet --no-pager -n 10
kubectl get nodes

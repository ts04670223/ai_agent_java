#!/bin/bash

# 快速配置腳本 - 用於手動觸發或測試

echo "================================"
echo "重新配置 Kong 路由"
echo "================================"

# 刪除舊的 Job（如果存在）
kubectl delete job kong-setup-routes 2>/dev/null || true

echo "等待舊 Job 清理完成..."
sleep 3

# 應用新的 Job
kubectl apply -f /vagrant/kong/kong-setup-routes-job.yaml

echo ""
echo "Job 已提交，等待執行..."
sleep 5

# 顯示狀態
kubectl get jobs kong-setup-routes

echo ""
echo "查看日誌:"
echo "  kubectl logs job/kong-setup-routes"
echo ""

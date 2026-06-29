#!/bin/bash
# 安裝 local-path-provisioner 作為預設 StorageClass
echo "安裝 local-path-provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

echo "設為預設 StorageClass..."
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "等待 provisioner 就緒..."
kubectl wait --for=condition=ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s

echo "=== StorageClass ==="
kubectl get sc
echo "=== PVC 狀態 ==="
kubectl get pvc

# Kong 配置快速參考

## 🚀 自動化已完成

下次重啟時 Kong 路由會**自動配置**，無需手動操作！

## ⚡ 快速命令

### 檢查並自動修復配置
```bash
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

### 強制重新配置
```bash
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

### 查看配置狀態
```bash
# 查看 Kong pods
vagrant ssh -c "kubectl get pods -l io.kompose.service=kong"

# 查看配置 Job
vagrant ssh -c "kubectl get jobs kong-setup-routes"

# 查看配置日誌
vagrant ssh -c "kubectl logs job/kong-setup-routes"

# 查看路由配置
vagrant ssh -c "curl -s http://localhost:30003/services"
vagrant ssh -c "curl -s http://localhost:30003/routes"
```

### 測試 API
```bash
# 產品列表
curl http://test6.test/api/products
curl http://localhost:30000/api/products

# 購物車
curl http://test6.test/api/cart/2
curl http://localhost:30000/api/cart/2
```

## 📋 系統啟動檢查清單

重啟後執行以下檢查：

- [ ] Kong pod 是否運行？  
  `kubectl get pods -l io.kompose.service=kong`
  
- [ ] 配置 Job 是否完成？  
  `kubectl get jobs kong-setup-routes`
  
- [ ] 路由是否配置？  
  `curl http://localhost:30003/services`
  
- [ ] API 是否可訪問？  
  `curl http://localhost:30000/api/products`

## 🔧 故障排除

### 問題：路由不工作
```bash
# 自動修復
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

### 問題：Job 失敗
```bash
# 查看日誌
kubectl logs job/kong-setup-routes

# 重新執行
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

### 問題：Kong pod 未啟動
```bash
# 查看 pod 狀態
kubectl describe pod -l io.kompose.service=kong

# 查看日誌
kubectl logs -l io.kompose.service=kong
```

## 📚 完整文檔

- [自動化配置指南](README-AUTOMATION.md) - 完整自動化說明
- [路由配置說明](README-ROUTES.md) - 路由詳細說明  
- [預防措施說明](README-PREVENTION.md) - 異常預防機制

## ✨ 檔案位置

```
kong/
├── kong-k8s.yaml                  # Kong Kubernetes 部署配置
├── kong-setup-routes-job.yaml     # 自動配置 Job（核心）
├── check-and-configure.sh         # 健康檢查腳本
├── reconfigure-routes.sh          # 快速重新配置
├── setup-routes.sh                # 手動配置腳本
└── README-*.md                    # 說明文檔
```

---
💡 提示：收藏此檔案，方便日後快速查閱！

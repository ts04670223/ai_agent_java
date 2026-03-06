# Kong 部署預防措施說明

## 已實施的預防措施

為了防止 Kong 在系統重啟或部署時出現網路和資料庫相關的異常，已在 `kong-k8s.yaml` 中實施以下改進：

### 1. Kong Deployment 初始化容器

#### wait-for-db
```yaml
- name: wait-for-db
  image: busybox:latest
  command:
    - sh
    - -c
    - |
      echo "等待 PostgreSQL 資料庫就緒..."
      until nc -zv kong-database 5432; do
        echo "資料庫尚未就緒，等待 2 秒後重試..."
        sleep 2
      done
      echo "資料庫已就緒！"
```
**作用：** 確保 Kong 容器只在資料庫端口可連接時才啟動

#### wait-for-migrations
```yaml
- name: wait-for-migrations
  image: postgres:16
  env:
    - name: PGPASSWORD
      value: kongpass
  command:
    - sh
    - -c
    - |
      echo "檢查資料庫遷移狀態..."
      until psql -h kong-database -U kong -d kong -c "SELECT * FROM schema_meta LIMIT 1;" > /dev/null 2>&1; do
        echo "等待資料庫遷移完成..."
        sleep 3
      done
      echo "資料庫遷移已完成！"
```
**作用：** 確保資料庫已完成 schema 初始化，Kong 不會因資料庫未 bootstrap 而啟動失敗

### 2. Kong 健康檢查

#### Liveness Probe（存活檢查）
```yaml
livenessProbe:
  tcpSocket:
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 5
```
**作用：** 檢測 Kong 是否仍在運行，如果連續 5 次失敗則重啟容器

#### Readiness Probe（就緒檢查）
```yaml
readinessProbe:
  tcpSocket:
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```
**作用：** 確保 Kong 完全就緒後才接收流量，防止過早發送請求導致 503 錯誤

### 3. Kong Migrations Job 初始化容器

```yaml
initContainers:
  - name: wait-for-postgres
    image: postgres:16
    env:
      - name: PGPASSWORD
        value: kongpass
    command:
      - sh
      - -c
      - |
        echo "等待 PostgreSQL 完全就緒..."
        until pg_isready -h kong-database -U kong -d kong; do
          echo "PostgreSQL 尚未就緒，等待 3 秒..."
          sleep 3
        done
        echo "PostgreSQL 已就緒，開始執行遷移..."
        sleep 5
```
**作用：** 確保 migrations job 只在 PostgreSQL 完全就緒後才執行，避免遷移失敗

## 解決的問題

### 問題 1: Flannel 網路初始化時序問題
**症狀：**
```
failed to setup network for sandbox: plugin type="flannel" failed (add): 
failed to load flannel 'subnet.env' file: open /run/flannel/subnet.env: no such file or directory
```

**解決方案：** 
- 初始化容器會等待資料庫連接成功，這增加了啟動延遲
- 給 Flannel 更多時間完成網路初始化
- 健康檢查確保 pod 只在完全就緒後標記為 Ready

### 問題 2: Kong 資料庫未初始化
**症狀：**
```
Database needs bootstrapping or is older than Kong 1.0.
To start a new installation from scratch, run 'kong migrations bootstrap'.
```

**解決方案：**
- `wait-for-migrations` 初始化容器檢查 `schema_meta` 表是否存在
- 確保 Kong 在資料庫完全初始化後才啟動
- Migrations job 的初始化容器確保資料庫就緒後才執行遷移

## 啟動順序

正確的啟動順序（已由初始化容器強制執行）：

```
1. PostgreSQL 資料庫啟動
   ↓
2. Flannel 網路插件初始化
   ↓
3. Kong Migrations Job 執行
   ├─ wait-for-postgres (init container)
   └─ kong migrations bootstrap
   ↓
4. Kong Deployment 啟動
   ├─ wait-for-db (init container)
   ├─ wait-for-migrations (init container)
   └─ kong (main container)
   ↓
5. 健康檢查通過，開始接收流量
```

## 測試驗證

### 正常啟動測試
```bash
kubectl get pods -l io.kompose.service=kong
# 應該看到: Running 狀態，READY 1/1
```

### 重啟測試
```bash
kubectl delete pod -l io.kompose.service=kong
sleep 40
kubectl get pods -l io.kompose.service=kong
# 應該自動恢復到 Running 狀態
```

### 查看初始化日誌
```bash
# 查看資料庫等待初始化容器
kubectl logs -l io.kompose.service=kong -c wait-for-db

# 查看遷移檢查初始化容器
kubectl logs -l io.kompose.service=kong -c wait-for-migrations
```

### 完整系統重啟測試
```bash
vagrant reload
# 等待系統完全啟動後
kubectl get pods
# Kong 應該自動啟動且狀態正常
```

## 故障排除

如果 Kong 仍然無法啟動：

1. **檢查初始化容器狀態：**
   ```bash
   kubectl describe pod -l io.kompose.service=kong
   ```

2. **檢查資料庫連接：**
   ```bash
   kubectl exec -it <kong-pod> -c wait-for-db -- sh
   nc -zv kong-database 5432
   ```

3. **手動執行遷移：**
   ```bash
   kubectl delete job kong-migrations
   kubectl apply -f kong-k8s.yaml
   ```

4. **重啟 Kong deployment：**
   ```bash
   kubectl rollout restart deployment/kong
   ```

## 配置檔案

所有改進已應用於：
- `kong/kong-k8s.yaml`

## 維護建議

1. **定期備份 Kong 資料庫**
   ```bash
   kubectl exec -it <postgres-pod> -- pg_dump -U kong kong > kong-backup.sql
   ```

2. **監控 Kong 狀態**
   ```bash
   watch kubectl get pods -l io.kompose.service=kong
   ```

3. **查看 Kong 日誌**
   ```bash
   kubectl logs -f -l io.kompose.service=kong
   ```

---
最後更新：2026-01-22

@echo off
REM Grafana 快速導入 Dashboard 工具

echo.
echo ========================================
echo   Grafana Dashboard 快速設定工具
echo ========================================
echo.
echo 正在開啟 Grafana Import 頁面...
echo.

start http://localhost:30300/dashboard/import

timeout /t 2 /nobreak >nul

echo ✅ 瀏覽器已開啟
echo.
echo 📋 請在 Import 頁面輸入以下 Dashboard ID：
echo.
echo 【Spring Boot 監控】
echo   4701  - JVM (Micrometer) - JVM 記憶體、GC、執行緒
echo   11378 - Spring Boot Statistics - HTTP 請求、錯誤率、回應時間
echo   12900 - Spring Boot Metrics - 全面的 Spring Boot 指標
echo   10280 - Spring Boot 2.1+ - Tomcat、Cache、DataSource
echo.
echo 【Kubernetes 監控】
echo   315   - Kubernetes Cluster - 叢集總覽
echo   8588  - K8s Deployment - Deployment 和 Pod 狀態
echo   13770 - K8s Pod Monitoring - Pod 資源使用詳情
echo.
echo 【Prometheus】
echo   3662  - Prometheus 2.0 Stats - Prometheus 性能監控
echo.
echo ────────────────────────────────────────
echo 📝 導入步驟：
echo   1. 在彈出的網頁中輸入 Dashboard ID（例如：4701）
echo   2. 點擊 [Load] 按鈕
echo   3. 選擇 Data source: Prometheus
echo   4. 點擊 [Import] 按鈕
echo   5. 重複以上步驟導入其他 Dashboard
echo ────────────────────────────────────────
echo.
echo 💡 建議優先導入：4701、11378、315
echo.
pause

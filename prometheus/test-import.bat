@echo off
echo.
echo ========================================
echo   測試 Dashboard - Spring Boot JVM
echo ========================================
echo.
echo 正在開啟 Grafana Import 頁面...
start http://localhost:30300/dashboard/import
echo.
echo ✅ 瀏覽器已開啟
echo.
echo 📋 導入步驟：
echo    1. 點擊 "Upload JSON file"
echo    2. 選擇檔案: prometheus\dashboards\spring-boot-jvm-fixed.json
echo    3. 選擇 Data source: Prometheus
echo    4. 點擊 Import
echo.
echo 💡 如果看不到圖表，請檢查：
echo    - Prometheus 資料源是否命名為 "prometheus"
echo    - 查詢語句是否返回數據
echo    - 時間範圍是否正確（預設最近 6 小時）
echo.
pause

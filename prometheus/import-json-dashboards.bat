@echo off
REM 使用 JSON 檔案導入 Grafana Dashboard

echo.
echo ========================================
echo   導入自訂 Grafana Dashboard (JSON)
echo ========================================
echo.

set GRAFANA_URL=http://localhost:30300
set GRAFANA_USER=admin
set GRAFANA_PASS=NewAdminPassword123

echo 正在導入 Dashboard...
echo.

echo [1/3] Spring Boot JVM 監控...
vagrant ssh -c "curl -X POST -H 'Content-Type: application/json' -u %GRAFANA_USER%:%GRAFANA_PASS% -d @/vagrant/prometheus/dashboards/spring-boot-jvm.json %GRAFANA_URL%/api/dashboards/import"
echo.

echo [2/3] Spring Boot HTTP 監控...
vagrant ssh -c "curl -X POST -H 'Content-Type: application/json' -u %GRAFANA_USER%:%GRAFANA_PASS% -d @/vagrant/prometheus/dashboards/spring-boot-http.json %GRAFANA_URL%/api/dashboards/import"
echo.

echo [3/3] Kubernetes Pod 監控...
vagrant ssh -c "curl -X POST -H 'Content-Type: application/json' -u %GRAFANA_USER%:%GRAFANA_PASS% -d @/vagrant/prometheus/dashboards/kubernetes-pods.json %GRAFANA_URL%/api/dashboards/import"
echo.

echo.
echo ========================================
echo ✅ Dashboard 導入完成！
echo ========================================
echo.
echo 📍 訪問 Grafana: %GRAFANA_URL%
echo    帳號: %GRAFANA_USER% / 密碼: %GRAFANA_PASS%
echo.
echo 📊 已導入的 Dashboard:
echo    - Spring Boot - JVM 監控
echo    - Spring Boot - HTTP 監控
echo    - Kubernetes - Pod 監控
echo.
pause

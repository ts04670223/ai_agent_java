@echo off
REM 完整驗證 test6.test 域名配置

echo ========================================
echo test6.test 域名完整驗證
echo ========================================
echo.

echo [檢查 1] Windows Hosts 配置
echo ----------------------------------------
findstr /C:"test6.test" C:\Windows\System32\drivers\etc\hosts >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Hosts 文件已配置
    findstr /C:"test6.test" C:\Windows\System32\drivers\etc\hosts
) else (
    echo ❌ Hosts 文件未配置
    echo 請添加: 192.168.10.10 test6.test
)
echo.

echo [檢查 2] Nginx 配置
echo ----------------------------------------
vagrant ssh -c "sudo nginx -t 2>&1 | grep -E 'successful|failed'"
echo.

echo [檢查 3] Kong Gateway 路由
echo ----------------------------------------
echo 查詢 Kong 路由...
vagrant ssh -c "curl -s http://localhost:30003/routes 2>/dev/null | grep -o '\"name\":\"[^\"]*\"' | sort -u"
echo.

echo [檢查 4] 服務連通性測試
echo ----------------------------------------
echo.
echo 測試前端 (http://test6.test/)
curl -s -o nul -w "  狀態: HTTP %%{http_code}\n" http://test6.test/
echo.

echo 測試後端 API (http://test6.test/api/products)
curl -s -o nul -w "  狀態: HTTP %%{http_code}\n" http://test6.test/api/products
echo.

echo 測試 Prometheus (http://test6.test/prometheus/api/v1/status/config)
curl -s -o nul -w "  狀態: HTTP %%{http_code}\n" http://test6.test/prometheus/api/v1/status/config
echo.

echo 測試 Grafana (http://test6.test/grafana/api/health)
curl -s -o nul -w "  狀態: HTTP %%{http_code}\n" http://test6.test/grafana/api/health
echo.

echo [檢查 5] Kong 後端服務狀態
echo ----------------------------------------
vagrant ssh -c "kubectl get pods -l app=app"
vagrant ssh -c "kubectl get pods -n monitoring"
echo.

echo ========================================
echo 驗證完成
echo ========================================
echo.
echo 訪問地址：
echo   🌐 前端:       http://test6.test/
echo   📡 後端 API:   http://test6.test/api/products
echo   📊 Prometheus: http://test6.test/prometheus
echo   📈 Grafana:    http://test6.test/grafana (admin/NewAdminPassword123)
echo.

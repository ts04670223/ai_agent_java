@echo off
REM 測試 test6.test 統一訪問

echo ========================================
echo 測試 test6.test 所有服務
echo ========================================
echo.

echo [1/4] 測試前端...
curl -s -o nul -w "HTTP %%{http_code}\n" http://test6.test/

echo [2/4] 測試後端 API...
curl -s -o nul -w "HTTP %%{http_code}\n" http://test6.test/api/products

echo [3/4] 測試 Prometheus...
curl -s -o nul -w "HTTP %%{http_code}\n" http://test6.test/prometheus/api/v1/status/config

echo [4/4] 測試 Grafana...
curl -s -o nul -w "HTTP %%{http_code}\n" http://test6.test/grafana/api/health

echo.
echo ========================================
echo 測試完成！
echo ========================================
echo.
echo 訪問地址：
echo   前端:       http://test6.test/
echo   後端 API:   http://test6.test/api
echo   Prometheus: http://test6.test/prometheus
echo   Grafana:    http://test6.test/grafana
echo.

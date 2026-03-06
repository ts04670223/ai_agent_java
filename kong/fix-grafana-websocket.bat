@echo off
REM Windows 版本的 Grafana WebSocket 修復腳本

echo ================================
echo 修復 Grafana WebSocket 配置
echo ================================
echo.

REM 設定 Kong Admin URL
set KONG_ADMIN_URL=http://localhost:30003

echo 刪除現有的 grafana-route...
curl -i -X DELETE %KONG_ADMIN_URL%/routes/grafana-route

echo.
echo --------------------------------
echo.

echo 創建支持 WebSocket 的 grafana-route...
curl -i -X POST %KONG_ADMIN_URL%/services/grafana/routes ^
  --data "name=grafana-route" ^
  --data "paths[]=/grafana" ^
  --data "strip_path=false" ^
  --data "protocols[]=http" ^
  --data "protocols[]=https" ^
  --data "protocols[]=ws" ^
  --data "protocols[]=wss"

echo.
echo --------------------------------
echo.

echo ================================
echo 驗證 Grafana 路由配置
echo ================================
echo.

curl -s %KONG_ADMIN_URL%/routes/grafana-route

echo.
echo ================================
echo 修復完成！
echo ================================
echo.
echo 請重新測試 WebSocket 連接：
echo   http://test6.test/grafana
echo.
echo WebSocket 端點應該可以正常工作：
echo   ws://test6.test/grafana/api/live/ws
echo.

pause

@echo off
REM Grafana WebSocket 快速修復（通過 Vagrant SSH）
REM 這個腳本會自動連接到 VM 並執行修復

echo ========================================
echo Grafana WebSocket 快速修復工具
echo ========================================
echo.
echo 這個工具會自動：
echo 1. 連接到 Vagrant VM
echo 2. 執行 WebSocket 修復
echo 3. 驗證配置
echo.
echo 按任意鍵開始修復...
pause > nul

cd /d c:\JOHNY\test

echo.
echo [1/3] 正在連接到 Vagrant VM...
echo.

REM 創建臨時修復腳本
echo KONG_ADMIN_URL="http://localhost:30003" > %TEMP%\fix-ws.sh
echo echo "刪除現有 grafana-route..." >> %TEMP%\fix-ws.sh
echo curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route >> %TEMP%\fix-ws.sh
echo echo "" >> %TEMP%\fix-ws.sh
echo echo "創建支持 WebSocket 的新路由..." >> %TEMP%\fix-ws.sh
echo curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes --data 'name=grafana-route' --data 'paths[]=/grafana' --data 'strip_path=false' --data 'protocols[]=http' --data 'protocols[]=https' --data 'protocols[]=ws' --data 'protocols[]=wss' >> %TEMP%\fix-ws.sh
echo echo "" >> %TEMP%\fix-ws.sh
echo echo "驗證配置..." >> %TEMP%\fix-ws.sh
echo curl -s ${KONG_ADMIN_URL}/routes/grafana-route ^| jq -r '.protocols[]' >> %TEMP%\fix-ws.sh

echo.
echo [2/3] 執行修復命令...
echo.

REM 通過 Vagrant SSH 執行修復命令
vagrant ssh -c "KONG_ADMIN_URL='http://localhost:30003'; curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route; echo ''; curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes --data 'name=grafana-route' --data 'paths[]=/grafana' --data 'strip_path=false' --data 'protocols[]=http' --data 'protocols[]=https' --data 'protocols[]=ws' --data 'protocols[]=wss'; echo ''; echo '驗證配置:'; curl -s ${KONG_ADMIN_URL}/routes/grafana-route | jq -r '.protocols[]' 2>/dev/null || curl -s ${KONG_ADMIN_URL}/routes/grafana-route"

echo.
echo [3/3] 修復完成！
echo.
echo ========================================
echo 測試說明
echo ========================================
echo.
echo 請在瀏覽器中訪問：
echo   http://test6.test/grafana
echo.
echo 打開開發者工具（F12），檢查：
echo   - 不應該再看到 WebSocket 錯誤
echo   - Network 標籤應該顯示 WebSocket 連接成功
echo.
echo 如果仍有問題，請查看詳細指南：
echo   kong\GRAFANA-WEBSOCKET-VM-FIX.md
echo.

pause

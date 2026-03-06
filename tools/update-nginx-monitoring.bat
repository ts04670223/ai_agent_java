@echo off
REM Windows 批次檔：更新 Nginx 監控配置

echo ================================
echo 更新 test6.test 監控路由
echo ================================
echo.

vagrant ssh -c "bash /vagrant/scripts/update-nginx-monitoring.sh"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================
    echo 更新完成！
    echo ================================
    echo.
    echo 請確認 Windows hosts 文件已配置：
    echo C:\Windows\System32\drivers\etc\hosts
    echo.
    echo 添加以下行：
    echo 192.168.10.10 test6.test
    echo.
    echo 訪問地址：
    echo   前端:       http://test6.test/
    echo   後端 API:   http://test6.test/api
    echo   Prometheus: http://test6.test/prometheus
    echo   Grafana:    http://test6.test/grafana
    echo.
) else (
    echo.
    echo ❌ 更新失敗
    exit /b 1
)

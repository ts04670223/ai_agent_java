@echo off
chcp 65001 >nul 2>&1
echo.
echo 等待應用啟動中...
echo.

:wait_loop
timeout /t 5 /nobreak >nul 2>nul
vagrant ssh -c "curl -s http://localhost:8080/actuator/health 2>/dev/null" >nul 2>&1
if %ERRORLEVEL% EQU 0 goto success

echo 仍在啟動... (按 Ctrl+C 可中斷)
goto wait_loop

:success
cls
echo ========================================
echo   應用啟動成功！
echo ========================================
echo.
echo 健康檢查:
vagrant ssh -c "curl -s http://localhost:8080/actuator/health"
echo.
echo.
echo 容器狀態:
vagrant ssh -c "cd /vagrant && docker compose ps"
echo.
echo ========================================
echo   可以訪問的服務:
echo ========================================
echo.
echo   主應用:    http://localhost:8080
echo   API 文檔:  http://localhost:8080/swagger-ui.html
echo   健康檢查:  http://localhost:8080/actuator/health
echo.
echo   MySQL:     localhost:3307
echo   Redis:     localhost:6379
echo.
pause

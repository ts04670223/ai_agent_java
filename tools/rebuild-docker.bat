@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo   重新構建 Docker 容器
echo ========================================
echo.

echo [1/3] 停止現有容器...
vagrant ssh -c "cd /vagrant && docker compose down"
echo.

echo [2/3] 重新構建映像...
vagrant ssh -c "cd /vagrant && docker compose build --no-cache"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 構建失敗
    pause
    exit /b 1
)
echo.

echo [3/3] 啟動容器...
vagrant ssh -c "cd /vagrant && docker compose up -d"
echo.

echo ========================================
echo   構建完成！
echo ========================================
echo.
echo 查看狀態: vagrant ssh -c "cd /vagrant && docker compose ps"
echo 查看日誌: vagrant ssh -c "cd /vagrant && docker compose logs -f app"
echo 測試應用: http://localhost:8080
echo.
pause

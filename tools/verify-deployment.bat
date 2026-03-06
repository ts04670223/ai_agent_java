@echo off
chcp 65001 >nul 2>&1
cls
echo ========================================
echo   驗證 Docker 應用部署
echo ========================================
echo.

echo [1/5] 檢查 Vagrant VM 狀態...
vagrant status | findstr "running"
if %ERRORLEVEL% NEQ 0 (
    echo [錯誤] Vagrant VM 未運行
    echo 請執行: vagrant up
    pause
    exit /b 1
)
echo [✓] Vagrant VM 正在運行
echo.

echo [2/5] 檢查 Docker 容器狀態...
vagrant ssh -c "cd /vagrant && docker compose ps" | findstr "healthy"
if %ERRORLEVEL% NEQ 0 (
    echo [警告] 部分容器不健康
)
echo [✓] 容器狀態檢查完成
echo.

echo [3/5] 測試 VM 內部訪問...
vagrant ssh -c "curl -s http://localhost:8080/actuator/health" | findstr "UP"
if %ERRORLEVEL% EQU 0 (
    echo [✓] VM 內部訪問正常
) else (
    echo [✗] VM 內部訪問失敗
)
echo.

echo [4/5] 測試 Windows 主機訪問...
curl.exe -s http://localhost:8080/actuator/health 2>nul | findstr "UP"
if %ERRORLEVEL% EQU 0 (
    echo [✓] Windows 主機訪問正常
) else (
    echo [✗] Windows 主機訪問失敗
    echo.
    echo 可能原因：
    echo   - 端口轉發未生效（需要 vagrant reload）
    echo   - Windows 防火牆阻止
    echo   - 容器未完全啟動
)
echo.

echo [5/5] 顯示服務信息...
echo.
echo ========================================
echo   服務訪問信息
echo ========================================
echo.
echo   主應用:     http://localhost:8080
echo   健康檢查:   http://localhost:8080/actuator/health
echo   API 文檔:   http://localhost:8080/swagger-ui.html
echo.
echo   MySQL:      localhost:3307
echo   用戶名:     springboot
echo   密碼:       springboot123
echo   資料庫:     spring_boot_demo
echo.
echo   Redis:      localhost:6379
echo.
echo ========================================
echo.
pause

@echo off
chcp 65001 >nul 2>&1
cls
echo ========================================
echo   修復並重啟 Docker 容器
echo ========================================
echo.
echo 此腳本將：
echo [1] 停止現有容器
echo [2] 重新構建映像（包含配置修復）
echo [3] 啟動新容器
echo [4] 驗證應用健康狀態
echo.
pause

echo.
echo [步驟 1/4] 停止並移除現有容器...
vagrant ssh -c "cd /vagrant && docker compose down"
echo.

echo [步驟 2/4] 重新構建 Docker 映像（這需要約 20 分鐘）...
echo 提示: 請耐心等待，Maven 正在下載依賴並編譯...
vagrant ssh -c "cd /vagrant && docker compose build --no-cache app"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] 構建失敗！
    echo.
    pause
    exit /b 1
)
echo.

echo [步驟 3/4] 啟動所有容器...
vagrant ssh -c "cd /vagrant && docker compose up -d"
echo.

echo 等待應用啟動（60秒）...
timeout /t 60 /nobreak
echo.

echo [步驟 4/4] 驗證應用狀態...
echo.
echo 容器狀態:
vagrant ssh -c "docker compose ps"
echo.

echo 應用健康檢查:
vagrant ssh -c "curl -s http://localhost:8080/actuator/health"
echo.
echo.

echo ========================================
echo   部署完成！
echo ========================================
echo.
echo 請訪問: http://localhost:8080
echo API 文檔: http://localhost:8080/swagger-ui.html
echo.
echo 如果仍有問題，請執行:
echo   vagrant ssh -c "docker compose logs -f app"
echo.
pause

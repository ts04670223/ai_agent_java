@echo off
echo ==========================================
echo 測試 Spring Boot + 前端整合
echo ==========================================

echo 1. 檢查後端是否運行...
curl -s http://localhost:8080/api/auth/test >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ 後端運行正常
) else (
    echo ✗ 後端未運行，請先啟動 Spring Boot 應用程式
    pause
    exit /b 1
)

echo.
echo 2. 測試產品API...
curl -s http://localhost:8080/api/products >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ 產品API正常
) else (
    echo ✗ 產品API測試失敗
)

echo.
echo 3. 檢查前端是否運行...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ 前端運行正常
) else (
    echo ✗ 前端未運行，請執行 npm run dev
)

echo.
echo ==========================================
echo 測試完成！
echo 如果所有測試都通過，請在瀏覽器中訪問：
echo 前端: http://localhost:3000
echo 後端API: http://localhost:8080/swagger-ui.html
echo ==========================================
pause
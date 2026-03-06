@echo off
chcp 65001 >nul 2>&1
cls
echo ========================================
echo   Docker 應用診斷工具
echo ========================================
echo.

echo [1/8] 檢查容器狀態...
vagrant ssh -c "docker compose ps"
echo.

echo [2/8] 檢查端口監聽...
vagrant ssh -c "ss -tlnp 2>/dev/null | grep -E '8080|3306|6379'"
echo.

echo [3/8] 測試 VM 內部訪問...
vagrant ssh -c "curl -s -o /dev/null -w 'HTTP Status: %%{http_code}\n' http://localhost:8080/actuator/health"
echo.

echo [4/8] 檢查 Redis 連接...
vagrant ssh -c "docker exec spring-boot-redis redis-cli ping" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Redis: OK
) else (
    echo Redis: 無法連接
)
echo.

echo [5/8] 檢查 MySQL 連接...
vagrant ssh -c "docker exec spring-boot-mysql mysqladmin ping -h localhost -u root -prootpassword 2>/dev/null"
if %ERRORLEVEL% EQU 0 (
    echo MySQL: OK
) else (
    echo MySQL: 無法連接
)
echo.

echo [6/8] 檢查應用環境變數...
vagrant ssh -c "docker exec spring-boot-app env | grep -E 'SPRING_REDIS_HOST|SPRING_DATASOURCE_URL'"
echo.

echo [7/8] 檢查最近的錯誤日誌...
echo 最近 20 行錯誤:
vagrant ssh -c "docker compose logs --tail 100 app 2>/dev/null | grep -i -E 'error|exception|failed|unable' | tail -20"
echo.

echo [8/8] 檢查網路連接...
echo 測試容器間網路:
vagrant ssh -c "docker exec spring-boot-app ping -c 2 redis 2>/dev/null"
vagrant ssh -c "docker exec spring-boot-app ping -c 2 mysql 2>/dev/null"
echo.

echo ========================================
echo   診斷完成
echo ========================================
echo.
echo 建議操作:
echo   1. 如果容器狀態異常: .\fix-and-restart.bat
echo   2. 如果需要查看完整日誌: vagrant ssh -c "docker compose logs -f app"
echo   3. 如果需要進入容器: .\docker-access.bat
echo.
pause

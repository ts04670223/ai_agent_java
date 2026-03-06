@echo off
chcp 65001 >nul 2>&1
cls
echo ========================================
echo   Docker 容器訪問工具
echo ========================================
echo.
echo 請選擇操作:
echo.
echo [1] 進入 Spring Boot 容器 (bash)
echo [2] 查看應用日誌 (實時)
echo [3] 查看所有容器狀態
echo [4] 進入 MySQL 資料庫
echo [5] 進入 Redis CLI
echo [6] 查看應用環境變數
echo [7] 測試應用健康狀態
echo [0] 退出
echo.
set /p choice="請輸入選項 (0-7): "

if "%choice%"=="1" goto spring_bash
if "%choice%"=="2" goto view_logs
if "%choice%"=="3" goto container_status
if "%choice%"=="4" goto mysql_cli
if "%choice%"=="5" goto redis_cli
if "%choice%"=="6" goto view_env
if "%choice%"=="7" goto health_check
if "%choice%"=="0" goto end
echo 無效選項！
pause
goto end

:spring_bash
echo.
echo 正在進入 Spring Boot 容器...
echo 提示: 使用 'exit' 離開容器
echo.
vagrant ssh -c "docker exec -it spring-boot-app bash"
goto end

:view_logs
echo.
echo 正在查看應用日誌 (Ctrl+C 退出)...
echo.
vagrant ssh -c "cd /vagrant && docker compose logs -f app"
goto end

:container_status
echo.
vagrant ssh -c "cd /vagrant && docker compose ps"
echo.
pause
goto end

:mysql_cli
echo.
echo 正在連接 MySQL...
echo 提示: 密碼是 springboot123
echo.
vagrant ssh -c "docker exec -it spring-boot-mysql mysql -u springboot -p spring_boot_demo"
goto end

:redis_cli
echo.
echo 正在連接 Redis...
echo.
vagrant ssh -c "docker exec -it spring-boot-redis redis-cli"
goto end

:view_env
echo.
echo 應用環境變數:
echo.
vagrant ssh -c "docker exec spring-boot-app env | grep -E 'SPRING|JAVA|PATH'"
echo.
pause
goto end

:health_check
echo.
echo 檢查應用健康狀態...
echo.
vagrant ssh -c "curl -s http://localhost:8080/actuator/health | python -m json.tool 2>nul || curl -s http://localhost:8080/actuator/health"
echo.
pause
goto end

:end

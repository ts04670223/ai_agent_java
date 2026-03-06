@echo off
REM Prometheus 管理腳本 (Windows)

set ACTION=%1
if "%ACTION%"=="" set ACTION=status

if "%ACTION%"=="install" goto install
if "%ACTION%"=="uninstall" goto uninstall
if "%ACTION%"=="restart" goto restart
if "%ACTION%"=="status" goto status
if "%ACTION%"=="logs" goto logs
if "%ACTION%"=="open" goto open
goto usage

:install
echo 安裝 Prometheus...
vagrant ssh -c "bash /vagrant/prometheus/prometheus.sh install"
goto end

:uninstall
echo 卸載 Prometheus...
vagrant ssh -c "bash /vagrant/prometheus/prometheus.sh uninstall"
goto end

:restart
echo 重啟 Prometheus...
vagrant ssh -c "bash /vagrant/prometheus/prometheus.sh restart"
goto end

:status
echo Prometheus 狀態:
vagrant ssh -c "bash /vagrant/prometheus/prometheus.sh status"
goto end

:logs
echo Prometheus 日誌:
vagrant ssh -c "bash /vagrant/prometheus/prometheus.sh logs"
goto end

:open
echo 打開 Prometheus...
start http://localhost:30090
goto end

:usage
echo 用法: %0 [install^|uninstall^|restart^|status^|logs^|open]
echo.
echo 命令:
echo   install    - 安裝 Prometheus
echo   uninstall  - 卸載 Prometheus
echo   restart    - 重啟 Prometheus
echo   status     - 查看狀態
echo   logs       - 查看日誌
echo   open       - 打開 Web UI
exit /b 1

:end

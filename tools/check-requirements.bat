@echo off
REM Check and install prerequisites for Kubernetes environment

echo ========================================
echo  Prerequisites Checker
echo ========================================
echo.

REM Check VirtualBox
echo Checking VirtualBox...
VBoxManage --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] VirtualBox is installed
    VBoxManage --version
) else (
    echo [MISSING] VirtualBox is NOT installed
    echo.
    echo Download and install from:
    echo https://www.virtualbox.org/wiki/Downloads
    echo.
    echo Or install via Chocolatey:
    echo   choco install virtualbox -y
    echo.
)
echo.

REM Check Vagrant
echo Checking Vagrant...
vagrant --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Vagrant is installed
    vagrant --version
) else (
    echo [MISSING] Vagrant is NOT installed
    echo.
    echo Download and install from:
    echo https://www.vagrantup.com/downloads
    echo.
    echo Or install via Chocolatey:
    echo   choco install vagrant -y
    echo.
)
echo.

echo ========================================
echo  Installation Options
echo ========================================
echo.
echo Option 1: Manual Installation
echo   1. Install VirtualBox: https://download.virtualbox.org/virtualbox/7.0.12/VirtualBox-7.0.12-159484-Win.exe
echo   2. Install Vagrant: https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0_windows_amd64.msi
echo   3. Restart PowerShell/CMD
echo   4. Run this script again
echo.
echo Option 2: Using Chocolatey (Recommended)
echo   Run PowerShell as Administrator:
echo   1. Install Chocolatey (if not installed):
echo      Set-ExecutionPolicy Bypass -Scope Process -Force;
echo      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
echo      iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo.
echo   2. Install VirtualBox and Vagrant:
echo      choco install virtualbox vagrant -y
echo.
echo   3. Restart PowerShell/CMD
echo   4. Run install.bat
echo.
echo ========================================

pause

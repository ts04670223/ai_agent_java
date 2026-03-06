# PowerShell script to install prerequisites
# Run as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto-Install Prerequisites" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Check if Chocolatey is installed
Write-Host "Checking Chocolatey..." -ForegroundColor Yellow
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Chocolatey is installed" -ForegroundColor Green
} else {
    Write-Host "[INSTALLING] Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "[OK] Chocolatey installed" -ForegroundColor Green
}
Write-Host ""

# Install VirtualBox
Write-Host "Checking VirtualBox..." -ForegroundColor Yellow
if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
    Write-Host "[OK] VirtualBox is already installed" -ForegroundColor Green
    VBoxManage --version
} else {
    Write-Host "[INSTALLING] VirtualBox..." -ForegroundColor Yellow
    choco install virtualbox -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "[OK] VirtualBox installed" -ForegroundColor Green
}
Write-Host ""

# Install Vagrant
Write-Host "Checking Vagrant..." -ForegroundColor Yellow
if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Vagrant is already installed" -ForegroundColor Green
    vagrant --version
} else {
    Write-Host "[INSTALLING] Vagrant..." -ForegroundColor Yellow
    choco install vagrant -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "[OK] Vagrant installed" -ForegroundColor Green
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close this PowerShell window" -ForegroundColor White
Write-Host "  2. Open a NEW PowerShell window (to refresh environment)" -ForegroundColor White
Write-Host "  3. Navigate to: cd C:\JOHNY\test" -ForegroundColor White
Write-Host "  4. Run: .\install.bat" -ForegroundColor White
Write-Host ""

pause

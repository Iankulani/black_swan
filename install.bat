@echo off
:: BLACK_SWAN_V4 - Windows Batch Installation Script
:: Author: Ian Carter Kulani
:: Version: 4.0.0

echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║        🦢 BLACK SWAN V4 - Windows Batch Installation                        ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠️ This script must be run as Administrator!
    echo    Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo 📦 Installing dependencies via Chocolatey...
echo.

:: Check if Chocolatey is installed
where chocolatey >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Chocolatey...
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

:: Install dependencies
choco upgrade -y python3 git nmap curl wget docker-desktop wireshark openssh nginx make cmake visualstudio-build-tools

echo.
echo 🐍 Installing Python packages...
echo.

:: Upgrade pip
python -m pip install --upgrade pip

:: Install requirements
if exist "requirements.txt" (
    pip install -r requirements.txt
    if %errorLevel% neq 0 (
        echo ⚠️ Full requirements failed, installing minimal...
        pip install -r requirements-minimal.txt
    )
) else (
    pip install requests psutil paramiko flask flask-socketio flask-cors discord.py telethon slack-sdk pynput pyautogui reportlab beautifulsoup4 dnspython whois scapy python-dotenv cryptography pyyaml
)

echo.
echo 📁 Creating directories...
echo.

mkdir .black_swan_v4 2>nul
mkdir black_swan_v4_reports 2>nul
mkdir logs 2>nul
mkdir temp 2>nul
mkdir data 2>nul
mkdir web-static 2>nul
mkdir redis-data 2>nul
mkdir postgres-data 2>nul

echo.
echo ⚙️ Creating configuration...
echo.

if not exist ".black_swan_v4\config.json" (
    (
        echo {
        echo     "version": "4.0.0",
        echo     "auto_start": false,
        echo     "auto_block_enabled": false,
        echo     "auto_block_threshold": 5,
        echo     "scan_timeout": 30,
        echo     "report_format": "html",
        echo     "generate_graphics": true,
        echo     "web": {
        echo         "enabled": true,
        echo         "port": 5000,
        echo         "host": "0.0.0.0"
        echo     },
        echo     "database": {
        echo         "type": "sqlite",
        echo         "path": ".black_swan_v4/black_swan_v4.db"
        echo     }
        echo }
    ) > .black_swan_v4\config.json
    echo ✅ Configuration created
)

echo.
echo 🔧 Creating startup script...
echo.

(
    echo @echo off
    echo echo 🦢 Starting BLACK_SWAN_V4...
    echo python black_swan.py %%*
) > start.bat

echo.
echo 🔥 Setting up firewall...
echo.

netsh advfirewall firewall add rule name="BLACK_SWAN_V4_Web" dir=in action=allow protocol=TCP localport=5000
netsh advfirewall firewall add rule name="BLACK_SWAN_V4_Phishing" dir=in action=allow protocol=TCP localport=8080
netsh advfirewall firewall add rule name="BLACK_SWAN_V4_HTTPS" dir=in action=allow protocol=TCP localport=8443
netsh advfirewall firewall add rule name="BLACK_SWAN_V4_C2" dir=in action=allow protocol=TCP localport=9000
netsh advfirewall firewall add rule name="BLACK_SWAN_V4_Agents" dir=in action=allow protocol=TCP localport=6000-6100

echo.
echo 🐳 Building Docker image...
echo.

if exist "Dockerfile" (
    docker build -t black_swan_v4:latest .
    echo ✅ Docker image built
)

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║        ✅ BLACK_SWAN_V4 Installation Complete!                            ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.
echo 📋 Installation Summary:
echo   📁 Installation Directory: %cd%
echo   🐍 Python: 
python --version
echo   🐳 Docker: 
docker --version 2>nul || echo   Docker not installed
echo.
echo 🎯 Next Steps:
echo   1. Run manually: start.bat
echo   2. Access web dashboard: http://localhost:5000
echo   3. Type 'help' for available commands
echo.
echo ⚠️  Remember: For authorized security testing only
echo.

pause
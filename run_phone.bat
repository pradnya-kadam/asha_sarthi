@echo off
setlocal
cd /d "%~dp0"
echo ================================================
echo AshaSarthi - RUN ON PHYSICAL PHONE
echo ================================================
echo.
set /p PC_IP=Enter your PC IPv4 address: 
if "%PC_IP%"=="" exit /b 1
call flutter pub get
call flutter devices
call flutter run -d RMX3844 --dart-define=API_BASE_URL=http://%PC_IP%:8000

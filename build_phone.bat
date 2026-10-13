@echo off
setlocal
cd /d "%~dp0"

echo ================================================
echo AshaSarthi - BUILD APK FOR PHYSICAL PHONE
echo ================================================
echo.
echo 1. Connect phone and PC to the SAME Wi-Fi.
echo 2. Run ipconfig on the PC and find IPv4 Address.
echo 3. Example: 192.168.1.7
echo.
set /p PC_IP=Enter your PC IPv4 address: 
if "%PC_IP%"=="" (
  echo No IP entered. Build cancelled.
  pause
  exit /b 1
)

echo.
echo Testing API URL: http://%PC_IP%:8000
call flutter clean
if errorlevel 1 goto fail
call flutter pub get
if errorlevel 1 goto fail
call flutter build apk --release --dart-define=API_BASE_URL=http://%PC_IP%:8000
if errorlevel 1 goto fail

echo.
echo ================================================
echo BUILD SUCCESSFUL
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Server URL: http://%PC_IP%:8000
echo ================================================
pause
exit /b 0

:fail
echo.
echo BUILD FAILED. Read the error above.
pause
exit /b 1

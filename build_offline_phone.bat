@echo off
setlocal
cd /d %~dp0

echo ==============================================
echo AshaSarthi - OFFLINE PHONE BUILD
echo ==============================================

echo.
echo This build does NOT require Wi-Fi or a browser.
echo User accounts and app data are stored in SQLite on the phone.
echo.

flutter clean
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter build apk --release
if errorlevel 1 exit /b 1

echo.
echo ==============================================
echo APK READY
echo ==============================================
echo build\app\outputs\flutter-apk\app-release.apk
pause

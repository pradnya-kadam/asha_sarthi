@echo off
setlocal
cd /d "%~dp0"

echo ==============================================
echo AshaSarthi - OFFLINE PHONE BUILD
echo ==============================================
echo.
echo This build does NOT require Wi-Fi or a browser.
echo Data and local accounts are stored in SQLite on the phone.
echo.

call flutter pub get
if errorlevel 1 goto fail

call flutter build apk --release
if errorlevel 1 goto fail

if not exist "build\app\outputs\flutter-apk\app-release.apk" (
  echo APK was not created.
  goto fail
)

echo.
echo ==============================================
echo APK READY
echo ==============================================
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
echo.

where adb >nul 2>nul
if errorlevel 1 (
  echo ADB was not found in PATH.
  echo Copy the APK to the phone manually and install it.
  goto done
)

echo Checking connected Android device...
adb devices
set /p INSTALL_NOW=Install APK on connected phone now? (Y/N): 
if /I "%INSTALL_NOW%"=="Y" (
  adb install -r "build\app\outputs\flutter-apk\app-release.apk"
  if errorlevel 1 goto fail
  echo.
  echo ==============================================
  echo INSTALLATION SUCCESSFUL
  echo ==============================================
  echo You can now unplug USB. The app remains installed.
)

goto done

:fail
echo.
echo ==============================================
echo BUILD/INSTALL FAILED
echo ==============================================
echo Read the error above.
exit /b 1

:done
echo.
echo Finished.
pause
exit /b 0

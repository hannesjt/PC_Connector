@echo off
:: Build script for PC Connector Android APK (release, split by ABI)
:: Run from the repo root.
::
:: Requirements:
::   Flutter SDK in PATH  (or set FLUTTER_HOME below)
::   Android SDK + JDK 17

setlocal

:: Optional: set paths if not already in PATH
:: set "FLUTTER_HOME=C:\development\SDK\flutter"
:: set "JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"
:: if defined FLUTTER_HOME set "PATH=%FLUTTER_HOME%\bin;%PATH%"

set "APP_DIR=%~dp0mobile_app"

if not exist "%APP_DIR%\pubspec.yaml" (
    echo ERROR: mobile_app\pubspec.yaml not found. Run from the repo root.
    exit /b 1
)

cd /d "%APP_DIR%"

echo.
echo === Getting Flutter packages ===
flutter pub get

echo.
echo === Building release APK (split per ABI) ===
flutter build apk --release --split-per-abi

echo.
set "OUT=%APP_DIR%\build\app\outputs\flutter-apk"
if exist "%OUT%\app-arm64-v8a-release.apk" (
    echo BUILD SUCCESSFUL
    echo Output folder: %OUT%
    dir /b "%OUT%\*.apk"
) else (
    echo BUILD FAILED - check output above.
    exit /b 1
)

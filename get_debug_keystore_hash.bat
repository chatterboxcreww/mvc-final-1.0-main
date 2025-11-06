@echo off
echo Generating Debug Keystore SHA-1 Certificate Fingerprint...
echo.

REM Default path for Android debug keystore on Windows
set KEYSTORE_PATH=%USERPROFILE%\.android\debug.keystore

if not exist "%KEYSTORE_PATH%" (
    echo Error: Debug keystore not found at %KEYSTORE_PATH%
    echo Please make sure you have built your Flutter project at least once.
    pause
    exit /b 1
)

echo Using keystore: %KEYSTORE_PATH%
echo.

REM Generate SHA-1
keytool -list -v -keystore "%KEYSTORE_PATH%" -alias androiddebugkey -storepass android -keypass android

echo.
echo Instructions:
echo 1. Copy the SHA-1 certificate fingerprint shown above
echo 2. Go to Firebase Console (https://console.firebase.google.com/)
echo 3. Open your project -> Project Settings -> General tab
echo 4. Under "Your apps", find your Android app and click "Add fingerprint"
echo 5. Paste the SHA-1 fingerprint and save
echo 6. Download the updated google-services.json file and replace the existing one
echo.
pause
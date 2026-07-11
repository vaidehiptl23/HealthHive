@echo off
setlocal enabledelayedexpansion

set "GIT_PATH=C:\Program Files\Git\cmd"

if not exist "%GIT_PATH%\git.exe" (
    set "GIT_PATH=C:\Program Files (x86)\Git\cmd"
)
if not exist "%GIT_PATH%\git.exe" (
    set "GIT_PATH=%USERPROFILE%\AppData\Local\Programs\Git\cmd"
)

if not exist "%GIT_PATH%\git.exe" (
    echo Git could not be found in standard installation paths.
    echo Please install Git for Windows first from https://git-scm.com/
    pause
    exit /b 1
)

echo Found Git at: %GIT_PATH%

rem Get the current User PATH environment variable from the registry
for /f "tokens=2*" %%A in ('reg query HKCU\Environment /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

echo !USER_PATH! | findstr /C:"%GIT_PATH%" >nul
if %errorlevel%==0 (
    echo Git is already in your PATH environment variable.
    echo Please restart your terminal/IDE (VS Code) for the changes to take effect.
    pause
    exit /b 0
)

rem Append Git path to User PATH
set "NEW_PATH=!USER_PATH!"
if not "!USER_PATH:~-1!"==";" (
    if defined USER_PATH (
        set "NEW_PATH=!NEW_PATH!;"
    )
)
set "NEW_PATH=!NEW_PATH!%GIT_PATH%"

reg add HKCU\Environment /v Path /t REG_SZ /d "!NEW_PATH!" /f

if %errorlevel%==0 (
    echo Successfully added Git to your User PATH environment variable!
    echo IMPORTANT: Please restart your terminal, command prompt, or VS Code for changes to take effect.
) else (
    echo Failed to update PATH in registry.
)

pause

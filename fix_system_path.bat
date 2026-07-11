@echo off
setlocal enabledelayedexpansion

echo Checking and repairing system environment variables...

set "SYS32=C:\Windows\System32"
set "WIN=C:\Windows"
set "WBEM=C:\Windows\System32\Wbem"
set "PS1=C:\Windows\System32\WindowsPowerShell\v1.0"
set "GIT=C:\Program Files\Git\cmd"

rem Query the current User PATH from Registry using absolute path to reg.exe
for /f "tokens=2*" %%A in ('C:\Windows\System32\reg.exe query HKCU\Environment /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

rem Check which paths are missing and append them
set "NEW_PATH=!USER_PATH!"

echo !USER_PATH! | C:\Windows\System32\findstr.exe /I /C:"%SYS32%" >nul
if %errorlevel% neq 0 (
    echo Adding %SYS32% to PATH...
    if not "!NEW_PATH:~-1!"==";" (
        if defined NEW_PATH (set "NEW_PATH=!NEW_PATH!;")
    )
    set "NEW_PATH=!NEW_PATH!%SYS32%"
)

echo !USER_PATH! | C:\Windows\System32\findstr.exe /I /C:"%WIN%" >nul
if %errorlevel% neq 0 (
    echo Adding %WIN% to PATH...
    if not "!NEW_PATH:~-1!"==";" (
        if defined NEW_PATH (set "NEW_PATH=!NEW_PATH!;")
    )
    set "NEW_PATH=!NEW_PATH!%WIN%"
)

echo !USER_PATH! | C:\Windows\System32\findstr.exe /I /C:"%WBEM%" >nul
if %errorlevel% neq 0 (
    echo Adding %WBEM% to PATH...
    if not "!NEW_PATH:~-1!"==";" (
        if defined NEW_PATH (set "NEW_PATH=!NEW_PATH!;")
    )
    set "NEW_PATH=!NEW_PATH!%WBEM%"
)

echo !USER_PATH! | C:\Windows\System32\findstr.exe /I /C:"%PS1%" >nul
if %errorlevel% neq 0 (
    echo Adding %PS1% to PATH...
    if not "!NEW_PATH:~-1!"==";" (
        if defined NEW_PATH (set "NEW_PATH=!NEW_PATH!;")
    )
    set "NEW_PATH=!NEW_PATH!%PS1%"
)

echo !USER_PATH! | C:\Windows\System32\findstr.exe /I /C:"%GIT%" >nul
if %errorlevel% neq 0 (
    echo Adding %GIT% to PATH...
    if not "!NEW_PATH:~-1!"==";" (
        if defined NEW_PATH (set "NEW_PATH=!NEW_PATH!;")
    )
    set "NEW_PATH=!NEW_PATH!%GIT%"
)

C:\Windows\System32\reg.exe add HKCU\Environment /v Path /t REG_SZ /d "!NEW_PATH!" /f

if %errorlevel%==0 (
    echo.
    echo Successfully restored Windows System paths and added Git to your User PATH!
    echo IMPORTANT: Please close and reopen all VS Code and terminal windows to apply the fix.
) else (
    echo Failed to update Registry.
)

pause

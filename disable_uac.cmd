@echo off
setlocal
:: Using batch script so that we don't invoke powershell (heavy) unnecessarily such as when called from git bash
:: Unnecessary NOP to unset errorlevel
(call )

:: UAC is already disabled
call :checkUac && exit /b %errorlevel%
echo Disabling UAC . . .

:: Relaunch as admin to set UAC registry key
fltmc >nul 2>&1 || goto :relaunch
reg ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d 0 /f > nul
exit /b %errorlevel%

:checkUac
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" | findstr "0x0" > nul
exit /b %errorlevel%

:relaunch
:: Relaunch the script with admin privilege if not already running as admin
powershell -Command "Start-Process cmd -ArgumentList '/c ""%~f0""' -Verb RunAs" >nul 2>&1

:: powershell -Verb RunAs doesn't return the error code of the elevated process, so check UAC to determine if disabling UAC was successful
call :checkUac
exit /b %errorlevel%

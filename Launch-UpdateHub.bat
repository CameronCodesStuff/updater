@echo off
title Update Hub
set "PS1=%~dp0UpdateHub.ps1"
if not exist "%PS1%" (
    echo UpdateHub.ps1 was not found next to this launcher.
    echo Put Launch-UpdateHub.bat and UpdateHub.ps1 in the same folder.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"
exit /b 0

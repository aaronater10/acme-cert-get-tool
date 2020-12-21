@echo off
cd /d "%~dp0"
setlocal EnableDelayedExpansion
setlocal EnableExtensions
title SSH Cached Remote Server Key Check
:: Sub Instance to Check Cached Remote Server Key


:: If temp file that closes this instance pre-exists, remove it so this instance can run
if exist "instance.close" (
    del /q "instance.close"
)


:: Check if user saved the remote server key into their registry, then closes upon TRUE
:: %1 = PuTTY Server Key Registry Location, %2 = Host Port, %3 = Host

:check_for_key
timeout 0 >nul

reg query %1 /v /f %2:%3 >nul && (

    taskkill /f /t /im "putty.exe" 2>nul >nul
    
    if exist "instance.close" (    
    del /q "instance.close"
    exit
    )
    
    goto :check_for_key
    
) || (
    
    if exist "instance.close" (    
    del /q "instance.close"
    exit
    )    

    goto :check_for_key
)
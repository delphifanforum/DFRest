@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"
title DFRest kurulum menusu

echo.
echo === DFRest kurulum ===
echo.
echo  1^) Delphi 10.3 Rio      ^(BDS 20.0^)  - Install_D103.bat
echo  2^) Delphi 10.4 Sydney   ^(BDS 21.0^)  - Install_D104.bat
echo  3^) Delphi 11 Alexandria ^(BDS 22.0^)  - Install_D11.bat
echo  4^) Delphi 12 Athens     ^(BDS 23.0^)  - Install_D12.bat
echo  5^) Delphi 13 Florence   ^(BDS 37.0^)  - Install_D13.bat
echo  0^) Cikis
echo.
set /p CHOICE=Secim (1-5): 

if "%CHOICE%"=="1" call "%~dp0Install_D103.bat" %* & exit /b %ERRORLEVEL%
if "%CHOICE%"=="2" call "%~dp0Install_D104.bat" %* & exit /b %ERRORLEVEL%
if "%CHOICE%"=="3" call "%~dp0Install_D11.bat" %* & exit /b %ERRORLEVEL%
if "%CHOICE%"=="4" call "%~dp0Install_D12.bat" %* & exit /b %ERRORLEVEL%
if "%CHOICE%"=="5" call "%~dp0Install_D13.bat" %* & exit /b %ERRORLEVEL%
if "%CHOICE%"=="0" exit /b 0

echo Gecersiz secim.
exit /b 1

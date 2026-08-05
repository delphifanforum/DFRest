@echo off
REM DFRest - Delphi 13 Florence (BDS 37.0)
cd /d "%~dp0"
call "%~dp0Install_Common.bat" D13 37.0 "Delphi 13 Florence" %*
exit /b %ERRORLEVEL%

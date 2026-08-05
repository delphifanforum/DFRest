@echo off
REM DFRest - Delphi 11 Alexandria (BDS 22.0)
cd /d "%~dp0"
call "%~dp0Install_Common.bat" D11 22.0 "Delphi 11 Alexandria" %*
exit /b %ERRORLEVEL%

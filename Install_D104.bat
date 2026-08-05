@echo off
REM DFRest - Delphi 10.4 Sydney (BDS 21.0)
cd /d "%~dp0"
call "%~dp0Install_Common.bat" D104 21.0 "Delphi 10.4 Sydney" %*
exit /b %ERRORLEVEL%

@echo off
REM DFRest - Delphi 12 Athens (BDS 23.0)
cd /d "%~dp0"
call "%~dp0Install_Common.bat" D12 23.0 "Delphi 12 Athens" %*
exit /b %ERRORLEVEL%

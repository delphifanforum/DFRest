@echo off
REM DFRest - Delphi 10.3 Rio (BDS 20.0)
cd /d "%~dp0"
call "%~dp0Install_Common.bat" D103 20.0 "Delphi 10.3 Rio" %*
exit /b %ERRORLEVEL%

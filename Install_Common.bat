@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM ============================================================================
REM  DFRest ortak kurulum motoru
REM  Cagri: call Install_Common.bat <PKGKEY> <BDSVER> <BASLIK> [/uninstall]
REM  Ornek: call Install_Common.bat D103 20.0 "Delphi 10.3 Rio"
REM ============================================================================

if "%~3"=="" (
  echo [HATA] Kullanım: Install_Common.bat PKGKEY BDSVER "Baslik" [/uninstall]
  echo Ornek: Install_Common.bat D104 21.0 "Delphi 10.4 Sydney"
  exit /b 1
)

set "PKGKEY=%~1"
set "BDSVER=%~2"
set "TITLE=%~3"
set "ACTION=%~4"

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "PKG=%ROOT%\Packages\%PKGKEY%"
set "OUT=%ROOT%\Lib\%PKGKEY%\Win32\Release"
set "RSVARS="
set "REGKEY=HKCU\Software\Embarcadero\BDS\%BDSVER%\Known Packages"
set "BPLDIR=%PUBLIC%\Documents\Embarcadero\Studio\%BDSVER%\Bpl"
set "DCPDIR=%PUBLIC%\Documents\Embarcadero\Studio\%BDSVER%\Dcp"

title DFRest - %TITLE% otomatik kurulum

if /I "%ACTION%"=="/uninstall" goto UNINSTALL
if /I "%ACTION%"=="-uninstall" goto UNINSTALL

echo.
echo === DFRest kurulum (%TITLE%) ===
echo Klasor : %ROOT%
echo Paket  : %PKG%
echo BDS    : %BDSVER%
echo Cikti  : %OUT%
echo.

REM --- rsvars bul ---
for %%P in (
  "%ProgramFiles(x86)%\Embarcadero\Studio\%BDSVER%\bin\rsvars.bat"
  "%ProgramFiles%\Embarcadero\Studio\%BDSVER%\bin\rsvars.bat"
  "C:\Program Files (x86)\Embarcadero\Studio\%BDSVER%\bin\rsvars.bat"
  "C:\Program Files\Embarcadero\Studio\%BDSVER%\bin\rsvars.bat"
) do (
  if exist %%~P (
    set "RSVARS=%%~P"
    goto FOUND_RSVARS
  )
)

echo [HATA] %TITLE% rsvars.bat bulunamadi.
echo Beklenen: ...\Embarcadero\Studio\%BDSVER%\bin\rsvars.bat
echo Bu Delphi surumu yuklu degilse once IDE'yi kurun.
exit /b 1

:FOUND_RSVARS
echo rsvars: %RSVARS%
echo.

if not exist "%PKG%\DFRest.dproj" (
  echo [HATA] Paket yok: %PKG%\DFRest.dproj
  exit /b 1
)
if not exist "%PKG%\dclDFRest.dproj" (
  echo [HATA] Design paket yok: %PKG%\dclDFRest.dproj
  exit /b 1
)

if not exist "%OUT%" mkdir "%OUT%"

echo [1/4] Ortam yukleniyor + runtime paket derleniyor...
call "%RSVARS%"
if errorlevel 1 (
  echo [HATA] rsvars calistirilamadi.
  exit /b 1
)

pushd "%PKG%"
msbuild "DFRest.dproj" /nologo /v:minimal /t:Build /p:Config=Release /p:Platform=Win32 ^
  /p:DCC_BplOutput="%OUT%" /p:DCC_DCPOutput="%OUT%" /p:DCC_ExeOutput="%OUT%" ^
  /p:GenPackage=true /p:GenDll=true /p:AppType=Package
if errorlevel 1 (
  echo.
  echo [HATA] DFRest.dproj derlenemedi.
  popd
  exit /b 1
)

echo.
echo [2/4] Design-time paket derleniyor...
msbuild "dclDFRest.dproj" /nologo /v:minimal /t:Build /p:Config=Release /p:Platform=Win32 ^
  /p:DCC_BplOutput="%OUT%" /p:DCC_DCPOutput="%OUT%" /p:DCC_ExeOutput="%OUT%" ^
  /p:DCC_DcpSearchPath="%OUT%" ^
  /p:GenPackage=true /p:GenDll=true /p:AppType=Package
if errorlevel 1 (
  echo.
  echo [HATA] dclDFRest.dproj derlenemedi.
  popd
  exit /b 1
)
popd

set "SRCDCL=%OUT%\dclDFRest.bpl"
set "SRCRUN=%OUT%\DFRest.bpl"

if not exist "%SRCDCL%" (
  echo [HATA] BPL bulunamadi: %SRCDCL%
  exit /b 1
)
if not exist "%SRCRUN%" (
  echo [HATA] Runtime BPL yok: %SRCRUN%
  echo Design paket DFRest.bpl olmadan IDE'de yuklenemez.
  exit /b 1
)

echo.
echo [3/4] BPL/DCP dosyalari IDE klasorune kopyalaniyor...
echo   Hedef Bpl: %BPLDIR%
if not exist "%BPLDIR%" mkdir "%BPLDIR%"
if not exist "%DCPDIR%" mkdir "%DCPDIR%"

copy /Y "%SRCRUN%" "%BPLDIR%\DFRest.bpl" >nul
copy /Y "%SRCDCL%" "%BPLDIR%\dclDFRest.bpl" >nul
if exist "%OUT%\DFRest.dcp" copy /Y "%OUT%\DFRest.dcp" "%DCPDIR%\DFRest.dcp" >nul
if exist "%OUT%\dclDFRest.dcp" copy /Y "%OUT%\dclDFRest.dcp" "%DCPDIR%\dclDFRest.dcp" >nul

set "BPL=%BPLDIR%\dclDFRest.bpl"
if not exist "%BPL%" (
  echo [HATA] Kopyalama basarisiz: %BPL%
  exit /b 1
)
if not exist "%BPLDIR%\DFRest.bpl" (
  echo [HATA] Runtime kopyalama basarisiz.
  exit /b 1
)

echo.
echo [4/4] IDE'ye kaydediliyor...
echo   %BPL%

REM Eski Lib yolu kayitlarini temizle
reg delete "%REGKEY%" /v "%ROOT%\Lib\Win32\Release\dclDFRest.bpl" /f >nul 2>&1
reg delete "%REGKEY%" /v "%OUT%\dclDFRest.bpl" /f >nul 2>&1

reg add "%REGKEY%" /v "%BPL%" /t REG_SZ /d "DFRest Type-safe REST" /f >nul
if errorlevel 1 (
  echo [HATA] Registry yazilamadi.
  exit /b 1
)

reg delete "HKCU\Software\Embarcadero\BDS\%BDSVER%\Disabled Packages" /v "%BPL%" /f >nul 2>&1
reg delete "HKCU\Software\Embarcadero\BDS\%BDSVER%\Disabled Packages" /v "%OUT%\dclDFRest.bpl" /f >nul 2>&1

echo.
echo === Kurulum tamam (%TITLE%) ===
echo.
echo Delphi'yi KAPATIP yeniden acin.
echo Tool Palette ^> DFRest ^> TDFRestClient
echo.
echo Kaldirmak icin: Install_%PKGKEY%.bat /uninstall
echo.
exit /b 0

:UNINSTALL
echo.
echo === DFRest kaldirma (%TITLE%) ===
set "BPL=%BPLDIR%\dclDFRest.bpl"
reg delete "%REGKEY%" /v "%BPL%" /f >nul 2>&1
reg delete "%REGKEY%" /v "%OUT%\dclDFRest.bpl" /f >nul 2>&1
reg delete "%REGKEY%" /v "%ROOT%\Lib\Win32\Release\dclDFRest.bpl" /f >nul 2>&1
if exist "%BPLDIR%\dclDFRest.bpl" del /f /q "%BPLDIR%\dclDFRest.bpl"
if exist "%BPLDIR%\DFRest.bpl" del /f /q "%BPLDIR%\DFRest.bpl"
if exist "%DCPDIR%\dclDFRest.dcp" del /f /q "%DCPDIR%\dclDFRest.dcp"
if exist "%DCPDIR%\DFRest.dcp" del /f /q "%DCPDIR%\DFRest.dcp"
echo Known Packages kaydi ve Public Bpl kopyalari silindi.
echo Delphi'yi yeniden baslatin.
echo.
exit /b 0

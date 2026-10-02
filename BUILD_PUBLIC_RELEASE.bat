@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo ============================================================
echo WL Simplistic SnowRunner Mod Editor v1.2.0L
echo Public Release Builder
echo ============================================================
echo.
echo This launcher hosts Windows PowerShell IN-PROCESS.
echo It does NOT launch powershell.exe at runtime.
echo It does NOT use ExecutionPolicy Bypass.
echo It does NOT extract the editor script to TEMP.
echo.

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
 echo ERROR: C# compiler not found.
 pause
 exit /b 1
)

rem Build-time discovery only: ask Windows PowerShell where its automation assembly lives.
set "SMA="
for /f "usebackq delims=" %%I in (`"%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "[System.Management.Automation.PSObject].Assembly.Location" 2^>nul`) do (
 if not defined SMA set "SMA=%%I"
)

rem Fallback to the .NET assembly cache.
if not defined SMA (
 for /f "delims=" %%I in ('dir /b /s "%WINDIR%\Microsoft.NET\assembly\GAC_MSIL\System.Management.Automation\System.Management.Automation.dll" 2^>nul') do (
  if not defined SMA set "SMA=%%I"
 )
)

if not defined SMA (
 echo ERROR: Could not locate System.Management.Automation.dll automatically.
 echo Nothing has been changed on this PC.
 pause
 exit /b 1
)
if not exist "%SMA%" (
 echo ERROR: PowerShell reported an automation assembly path that does not exist:
 echo %SMA%
 pause
 exit /b 1
)

echo Compiler: %CSC%
echo PowerShell automation assembly:
echo %SMA%
echo.

if exist "WL-Simplistic-SnowRunner-Mod-Editor.exe" del /q "WL-Simplistic-SnowRunner-Mod-Editor.exe"
"%CSC%" /nologo /target:winexe /platform:anycpu /optimize+ /out:"WL-Simplistic-SnowRunner-Mod-Editor.exe" /win32icon:"assets\WL-icon.ico" /reference:"%SMA%" /reference:System.dll /reference:System.Core.dll /reference:System.Windows.Forms.dll /resource:"WL-Simplistic-SnowRunner-Mod-Editor.ps1",WL.Editor.ps1 WL-Launcher.cs
if errorlevel 1 (
 echo.
 echo BUILD FAILED.
 pause
 exit /b 1
)

echo.
echo BUILD SUCCEEDED.
echo.

rem Prepare a clean folder containing only files intended for public distribution.
if exist "PUBLIC_RELEASE" rmdir /s /q "PUBLIC_RELEASE"
mkdir "PUBLIC_RELEASE"
mkdir "PUBLIC_RELEASE\assets"
copy /y "WL-Simplistic-SnowRunner-Mod-Editor.exe" "PUBLIC_RELEASE\" >nul
copy /y "README.txt" "PUBLIC_RELEASE\" >nul
copy /y "FEATURE_GUIDE.txt" "PUBLIC_RELEASE\" >nul
copy /y "ANTIVIRUS_AND_SAFETY.txt" "PUBLIC_RELEASE\" >nul
copy /y "assets\WL-header-logo.png" "PUBLIC_RELEASE\assets\" >nul
copy /y "assets\WL-icon.ico" "PUBLIC_RELEASE\assets\" >nul
copy /y "assets\WL-icon.png" "PUBLIC_RELEASE\assets\" >nul

echo PUBLIC_RELEASE folder prepared.
echo.
echo RELEASE CHECKLIST:
echo 1. Do NOT whitelist or Allow the EXE before scanning.
echo 2. Scan the EXE and PUBLIC_RELEASE folder with Microsoft Defender.
echo 3. Launch the EXE and run Preview Changes.
echo 4. Perform one known-good Apply / in-game / Restore Original smoke test.
echo 5. Zip ONLY the PUBLIC_RELEASE folder contents for public distribution.
echo 6. Keep this source/build package private as your reproducible build baseline.
echo.
echo IMPORTANT: A clean Defender scan on your PC does not guarantee every antivirus
 echo vendor will classify a new unsigned executable identically. Code signing can
 echo improve publisher reputation for future public releases.
echo.
pause

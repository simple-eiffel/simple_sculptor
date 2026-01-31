@echo off
REM Build script for Sculptor Viewer application
REM This script compiles the viewer application and prepares binaries for distribution

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Sculptor Viewer Build Script
echo ========================================
echo.

REM Check prerequisites
echo [1/5] Checking prerequisites...

if not defined SIMPLE_EIFFEL (
	echo ERROR: SIMPLE_EIFFEL environment variable not set
	echo Please set it to the simple_eiffel libraries path (e.g., D:\prod)
	exit /b 1
)

if not exist "%SIMPLE_EIFFEL%\simple_browser\simple_browser.ecf" (
	echo ERROR: simple_browser not found at %SIMPLE_EIFFEL%\simple_browser
	exit /b 1
)

if not exist "%SIMPLE_EIFFEL%\simple_vision\simple_vision.ecf" (
	echo ERROR: simple_vision not found at %SIMPLE_EIFFEL%\simple_vision
	exit /b 1
)

echo [OK] Prerequisites verified

REM Compile application
echo.
echo [2/5] Compiling Sculptor Viewer application...
echo.

REM Use melting (incremental) build for faster iteration
call /d/prod/ec.sh -batch -config simple_sculptor.ecf -target sculptor_viewer -c_compile

if errorlevel 1 (
	echo ERROR: Compilation failed
	exit /b 1
)

echo [OK] Compilation successful

REM Check for compiled executable
echo.
echo [3/5] Locating compiled executable...

if exist "EIFGENs\sculptor_viewer\W_code\sculptor_viewer.exe" (
	echo [OK] Found: EIFGENs\sculptor_viewer\W_code\sculptor_viewer.exe
	set EXE_PATH=EIFGENs\sculptor_viewer\W_code\sculptor_viewer.exe
	set DLL_PATH=EIFGENs\sculptor_viewer\W_code
) else if exist "EIFGENs\sculptor_viewer\F_code\sculptor_viewer.exe" (
	echo [OK] Found: EIFGENs\sculptor_viewer\F_code\sculptor_viewer.exe
	set EXE_PATH=EIFGENs\sculptor_viewer\F_code\sculptor_viewer.exe
	set DLL_PATH=EIFGENs\sculptor_viewer\F_code
) else (
	echo ERROR: Executable not found
	exit /b 1
)

REM Create bin directory
echo.
echo [4/5] Preparing bin directory...

if not exist "bin" mkdir bin

REM Copy executable
copy /Y "!EXE_PATH!" "bin\sculptor_viewer.exe" >nul
if errorlevel 1 (
	echo ERROR: Failed to copy executable
	exit /b 1
)

REM Copy DLLs
echo Copying runtime DLLs...
for /r "!DLL_PATH!" %%F in (*.dll) do (
	copy /Y "%%F" "bin\" >nul
)

REM Copy web resources
echo Copying web resources...
if not exist "bin\web" mkdir "bin\web"
xcopy /Y /E "web\*" "bin\web\" >nul

echo [OK] Binaries prepared in bin\ directory

REM Summary
echo.
echo [5/5] Build Summary
echo ========================================
echo.
echo Executable: bin\sculptor_viewer.exe
echo Web Resources: bin\web\
echo.
echo To run the application:
echo   .\bin\sculptor_viewer.exe
echo.
echo ========================================
echo Build complete!
echo ========================================
echo.

endlocal

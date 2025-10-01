@echo off
setlocal enabledelayedexpansion

echo(
echo ========================================
echo   Random Article Generator
echo ========================================
echo(

REM Hardcoded project directory - works from anywhere
set SCRIPT_DIR=D:\.biz\websites\standalone\aff-article-gen

echo Project directory: %SCRIPT_DIR%
echo(

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    pause
    goto :EOF
)

REM Check if Flask is already running
curl -s http://127.0.0.1:5000/ >nul 2>&1
set FLASK_RUNNING=%errorlevel%

set FLASK_PID=
set STARTED_FLASK=0

if !FLASK_RUNNING! NEQ 0 (
    echo Starting Flask server...
    echo(

    REM Start Flask in a new window with a unique title (using absolute path)
    set FLASK_WINDOW_TITLE=FlaskServer_%RANDOM%
    start "!FLASK_WINDOW_TITLE!" /MIN /D "%SCRIPT_DIR%" python "%SCRIPT_DIR%\app.py"

    REM Wait a bit for the process to spawn
    timeout /t 2 /nobreak >nul

    REM Get the PID of the window we just created
    for /f "tokens=2" %%a in ('tasklist /FI "WINDOWTITLE eq !FLASK_WINDOW_TITLE!" /FI "IMAGENAME eq python.exe" /NH 2^>nul ^| find "python.exe"') do (
        set FLASK_PID=%%a
    )

    REM If PID detection failed, try alternative method
    if "!FLASK_PID!"=="" (
        echo Warning: Could not detect Flask PID, will check if it's running...
    ) else (
        echo Flask PID detected: !FLASK_PID!
    )

    REM Wait for Flask to actually start responding (max 30 seconds)
    set WAIT=0
    :WAIT_LOOP
    timeout /t 2 /nobreak >nul
    curl -s http://127.0.0.1:5000/ >nul 2>&1
    if errorlevel 1 (
        set /a WAIT+=1
        if !WAIT! LSS 15 (
            echo Waiting for Flask... (!WAIT!/15^)
            goto WAIT_LOOP
        )
        echo(
        echo ERROR: Flask failed to start after 30 seconds
        echo(
        echo Please check for errors by running manually:
        echo    python app.py
        echo(
        if not "!FLASK_PID!"=="" (
            echo Cleaning up Flask process...
            taskkill /PID !FLASK_PID! /F >nul 2>&1
        )
        pause
        goto :EOF
    )

    echo Flask server started successfully!
    echo(
    set STARTED_FLASK=1
) else (
    echo Flask already running - using existing server
    echo(
    set STARTED_FLASK=0
)

REM Generate article using absolute path
echo Generating article...
echo(
echo ----------------------------------------
cd /d "%SCRIPT_DIR%" && python "%SCRIPT_DIR%\generate_random_article.py"
set RESULT=%errorlevel%
echo ----------------------------------------
echo(

REM Cleanup - only if we started Flask ourselves
if !STARTED_FLASK! EQU 1 (
    echo(
    echo Stopping Flask server...

    if not "!FLASK_PID!"=="" (
        echo Killing Flask process (PID: !FLASK_PID!^)...
        taskkill /PID !FLASK_PID! /F >nul 2>&1
    ) else (
        REM Fallback: kill by window title
        for /f "tokens=2" %%a in ('tasklist /FI "WINDOWTITLE eq !FLASK_WINDOW_TITLE!" /FI "IMAGENAME eq python.exe" /NH 2^>nul ^| find "python.exe"') do (
            echo Killing Flask process (PID: %%a^)...
            taskkill /PID %%a /F >nul 2>&1
        )
    )

    echo Flask stopped.
)

REM Check result
if !RESULT! NEQ 0 (
    echo(
    echo ========================================
    echo   GENERATION FAILED
    echo ========================================
    echo(
    echo Check error messages above
    echo(
    pause
    goto :EOF
)

echo(
echo ========================================
echo   SUCCESS!
echo ========================================
echo(
echo Article generated and saved!
echo Location: %SCRIPT_DIR%\verse329.github.io\articles\posted\
echo(

pause
endlocal

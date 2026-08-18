@echo off
title DermaSense - Auto Pull from GitHub

echo ============================================
echo    DermaSense - Auto GitHub Pull
echo ============================================
echo.

cd /d "c:\Users\Acer\Desktop\DermaSense"

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/
    pause
    exit /b 1
)

if not exist ".git" (
    echo [ERROR] This is not a Git repository.
    echo Initializing and connecting to remote...
    git init
    git remote add origin https://github.com/subiksenvs/DermaSense.git
    git branch -M main
)

echo [INFO] Checking for local changes before pulling...
echo.
git status --short

REM Check for uncommitted changes
git diff --quiet --cached 2>nul
set CACHED=%errorlevel%
git diff --quiet 2>nul
set WORKING=%errorlevel%

if "%CACHED%" neq "0" (
    echo.
    echo [WARNING] You have staged changes. Stashing them before pull...
    git stash push -m "Auto-stash before pull - %DATE% %TIME%"
    set STASHED=1
)

if "%WORKING%" neq "0" (
    if not defined STASHED (
        echo.
        echo [WARNING] You have unstaged changes. Stashing them before pull...
        git stash push -m "Auto-stash before pull - %DATE% %TIME%"
        set STASHED=1
    )
)

echo.
echo [INFO] Fetching latest changes from GitHub...
git fetch origin main

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Fetch failed! Check your internet connection.
    pause
    exit /b 1
)

echo.
echo [INFO] Pulling latest changes from GitHub (main branch)...
git pull origin main

if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Pull failed. Trying with --rebase...
    git pull --rebase origin main

    if %errorlevel% neq 0 (
        echo.
        echo [ERROR] Pull failed! There may be merge conflicts.
        echo Please resolve conflicts manually and try again.
        if defined STASHED (
            echo [INFO] Your stashed changes are saved. Run "git stash pop" after resolving.
        )
        pause
        exit /b 1
    )
)

REM Restore stashed changes if any
if defined STASHED (
    echo.
    echo [INFO] Restoring your stashed local changes...
    git stash pop

    if %errorlevel% neq 0 (
        echo.
        echo [WARNING] Could not auto-restore stashed changes (possible conflicts).
        echo Run "git stash pop" manually and resolve any conflicts.
    ) else (
        echo [INFO] Local changes restored successfully!
    )
)

echo.
echo ============================================
echo    Successfully pulled from GitHub!
echo ============================================
echo.
echo Repository: https://github.com/subiksenvs/DermaSense
echo Branch:     main
echo.
pause

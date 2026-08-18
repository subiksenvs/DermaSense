@echo off
title DermaSense - Auto Push to GitHub

echo ============================================
echo    DermaSense - Auto GitHub Push
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

echo [INFO] Checking for changes...
echo.
git status --short

git diff --quiet --cached 2>nul
set CACHED=%errorlevel%
git diff --quiet 2>nul
set WORKING=%errorlevel%

for /f %%i in ('git ls-files --others --exclude-standard') do set UNTRACKED=1

if "%CACHED%"=="0" if "%WORKING%"=="0" if not defined UNTRACKED (
    echo.
    echo [INFO] No changes detected. Repository is up to date!
    pause
    exit /b 0
)

echo.
echo [INFO] Staging all changes...
git add -A

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set DATETIME=%%I
set DATESTAMP=%DATETIME:~0,4%-%DATETIME:~4,2%-%DATETIME:~6,2%
set TIMESTAMP=%DATETIME:~8,2%:%DATETIME:~10,2%:%DATETIME:~12,2%

set COMMIT_MSG=Update DermaSense - %DATESTAMP% %TIMESTAMP%

echo [INFO] Committing: "%COMMIT_MSG%"
git commit -m "%COMMIT_MSG%"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Commit failed!
    pause
    exit /b 1
)

echo.
echo [INFO] Pushing to GitHub (main branch)...
git push origin main

if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Push failed. Trying with --set-upstream...
    git push --set-upstream origin main

    if %errorlevel% neq 0 (
        echo.
        echo [ERROR] Push failed! Check your internet connection and credentials.
        pause
        exit /b 1
    )
)

echo.
echo ============================================
echo    Successfully pushed to GitHub!
echo ============================================
echo.
echo Repository: https://github.com/subiksenvs/DermaSense
echo Branch:     main
echo.
pause

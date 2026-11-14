@echo off
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\ucrt64\bin;%PATH%"
cd /d "%~dp0"
echo Pushing Basketball Bounceback to https://github.com/rushia407/Basket-bounce.git ...
git push -u origin main
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==============================================
    echo [SUCCESS] Code pushed to GitHub successfully!
    echo ==============================================
) else (
    echo.
    echo ==============================================
    echo [ERROR] Push failed or authentication cancelled.
    echo ==============================================
)
pause
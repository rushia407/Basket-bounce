@echo off
cd /d "%~dp0"
echo ==============================================
echo   Starting Basketball Bounceback (Godot 4)
echo   Theme: Bounce Back
echo ==============================================

set "GODOT_EXE=godot"
where godot >nul 2>&1
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" (
        set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    )
)

"%GODOT_EXE%" --path "%~dp0"
if errorlevel 1 (
    echo.
    echo Godot executable not found on PATH or WinGet links.
    echo Please open Godot and select this project folder.
    pause
)

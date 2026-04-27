@echo off
title Установщик скилов для AI-ассистентов
echo ====================================================
echo   Установка скилов из репозитория usliders/skills
echo ====================================================
echo.

rem Запускаем PowerShell с нужными параметрами
powershell -ExecutionPolicy Bypass -NoProfile -Command ^
    "& { [ScriptBlock]::Create((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/usliders/skills/main/install.ps1' -UseBasicParsing).Content).Invoke(@('%~dp0')) }"

if %errorlevel% neq 0 (
    echo.
    echo [ОШИБКА] Не удалось выполнить скрипт установки.
    pause
    exit /b 1
)

echo.
echo Установка завершена.
pause
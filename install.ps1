@echo off
setlocal enabledelayedexpansion
title Установщик скилов для AI-ассистентов
chcp 65001 >nul

:: Проверяем, есть ли git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ОШИБКА] git не найден в системе.
    echo Пожалуйста, установите Git для Windows: https://git-scm.com/download/win
    echo Или установите WSL и используйте bash-скрипт.
    pause
    exit /b 1
)

set "REPO_URL=https://github.com/usliders/skills.git"
set "REPO_BRANCH=main"

:: Запоминаем текущую папку (где запущен скрипт)
set "CURRENT_DIR=%CD%"

:: Временная папка для клонирования
set "TEMP_DIR=%TEMP%\skills-%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

echo [INFO] Клонируем репозиторий %REPO_URL% (ветка %REPO_BRANCH%)...
git clone --depth 1 --branch "%REPO_BRANCH%" "%REPO_URL%" "%TEMP_DIR%" 2>nul
if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось клонировать репозиторий. Проверьте интернет.
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 1
)

:: Определяем папку со скилами (либо корень, либо /skills)
if exist "%TEMP_DIR%\skills" (
    set "SKILLS_SRC=%TEMP_DIR%\skills"
) else (
    set "SKILLS_SRC=%TEMP_DIR%"
)

:: Собираем список скилов (папки с SKILL.md)
set "SKILL_LIST="
for /d %%d in ("%SKILLS_SRC%\*") do (
    if exist "%%d\SKILL.md" (
        set "SKILL_NAME=%%~nxd"
        set "SKILL_LIST=!SKILL_LIST! !SKILL_NAME!"
    )
)

if "!SKILL_LIST!"=="" (
    echo [ОШИБКА] В репозитории не найдено ни одного скила (SKILL.md).
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 1
)

echo.
echo Найдены скилы:
set /a count=0
for %%s in (!SKILL_LIST!) do (
    set /a count+=1
    echo   !count!. %%s
)

:: Интерактивный выбор AI-ассистента
echo.
echo Выберите AI-ассистента (путь для установки):
echo   1. Claude Code        -> .claude\skills
echo   2. Cursor             -> .cursor\skills
echo   3. Gemini CLI         -> .gemini\skills
echo   4. Pi                 -> .pi\skills
echo   5. Codex CLI          -> .codex\skills
echo   6. Antigravity        -> .agent\skills
echo   7. GitHub Copilot     -> .github\skills
echo   8. Windsurf           -> .windsurf\skills
echo   9. Augment Code       -> .augment\skills
echo   10. Универсальный      -> .agents\skills
echo   11. BoltAI             -> .bolt\skills
echo   12. Ручной ввод
echo   13. Отмена
set /p "assist_choice=Ваш выбор (1-13): "

if "%assist_choice%"=="13" (
    echo Установка отменена.
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 0
)

set "TARGET_DIR="
if "%assist_choice%"=="1" set "TARGET_DIR=.claude\skills"
if "%assist_choice%"=="2" set "TARGET_DIR=.cursor\skills"
if "%assist_choice%"=="3" set "TARGET_DIR=.gemini\skills"
if "%assist_choice%"=="4" set "TARGET_DIR=.pi\skills"
if "%assist_choice%"=="5" set "TARGET_DIR=.codex\skills"
if "%assist_choice%"=="6" set "TARGET_DIR=.agent\skills"
if "%assist_choice%"=="7" set "TARGET_DIR=.github\skills"
if "%assist_choice%"=="8" set "TARGET_DIR=.windsurf\skills"
if "%assist_choice%"=="9" set "TARGET_DIR=.augment\skills"
if "%assist_choice%"=="10" set "TARGET_DIR=.agents\skills"
if "%assist_choice%"=="11" set "TARGET_DIR=.bolt\skills"

if "%assist_choice%"=="12" (
    set /p "TARGET_DIR=Введите путь (например: .my-skills): "
)

if "%TARGET_DIR%"=="" (
    echo Неверный выбор.
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 1
)

:: Создаём целевую папку в текущем проекте
set "FULL_TARGET=%CURRENT_DIR%\%TARGET_DIR%"
mkdir "%FULL_TARGET%" 2>nul

echo.
echo Устанавливаем скилы в %FULL_TARGET%...

:: Копируем все скилы (можно позже добавить выбор конкретных)
:: Для простоты копируем всё. Если нужен выбор по номерам — допишу.
for /d %%d in ("%SKILLS_SRC%\*") do (
    if exist "%%d\SKILL.md" (
        set "SK_NAME=%%~nxd"
        set "DEST_DIR=%FULL_TARGET%\!SK_NAME!"
        if exist "!DEST_DIR!" rmdir /s /q "!DEST_DIR!" 2>nul
        xcopy "%%d" "!DEST_DIR!" /E /I /Q >nul
        echo   [OK] !SK_NAME!
    )
)

echo.
echo [ГОТОВО] Скилы установлены в %TARGET_DIR%
echo Теперь ваш AI-ассистент сможет их использовать.

:: Очистка
rmdir /s /q "%TEMP_DIR%" 2>nul

echo.
pause

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Установка скилов из репозитория usliders/skills в текущий проект.
.DESCRIPTION
    Скрипт проверяет наличие Git, при необходимости находит его в стандартных папках
    или предлагает автоматическую установку через winget. Затем клонирует репозиторий,
    предлагает выбрать AI-ассистента и установить нужные скилы.
.EXAMPLE
    iex (iwr -Uri 'https://raw.githubusercontent.com/usliders/skills/main/install.ps1' -UseBasicParsing).Content
#>

param(
    [string]$RepoUrl = "https://github.com/usliders/skills.git",
    [string]$Branch = "main",
    [string]$TargetDir = "",
    [switch]$AllSkills
)

# Цвета и стили
$InfoColor = "Cyan"
$SuccessColor = "Green"
$WarnColor = "Yellow"
$ErrorColor = "Red"

function Write-Info   { Write-Host "[INFO] $args" -ForegroundColor $InfoColor }
function Write-Success{ Write-Host "[OK]   $args" -ForegroundColor $SuccessColor }
function Write-Warning{ Write-Host "[WARN] $args" -ForegroundColor $WarnColor }
function Write-Error  { Write-Host "[ERROR] $args" -ForegroundColor $ErrorColor; exit 1 }

# ============================================================
# 1. Обеспечение наличия Git
# ============================================================
function Find-GitManually {
    # Возможные пути установки Git в Windows
    $possiblePaths = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "$env:ProgramFiles\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\bin\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\git.exe"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $gitDir = Split-Path $path
            # Добавляем в PATH текущей сессии
            $env:Path = "$gitDir;$env:Path"
            Write-Success "Найден Git по пути: $path (добавлен в PATH сессии)"
            return $true
        }
    }
    return $false
}

function Ensure-Git {
    # Если git уже доступен
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Success "Git найден: $(git --version)"
        return $true
    }

    # Попробуем найти вручную в стандартных папках
    Write-Warning "Git не найден в PATH. Пытаюсь найти в стандартных папках..."
    if (Find-GitManually) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    # Если не нашли — предлагаем установить
    Write-Warning "Git не установлен или не найден."
    $response = Read-Host "Хотите автоматически установить Git через winget? (y/n, потребует прав администратора)"
    if ($response -ne 'y') {
        Write-Error "Установите Git вручную: https://git-scm.com/download/win"
    }

    # Проверка прав администратора
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Warning "Требуются права администратора. Перезапускаем скрипт с повышенными правами..."
        # Определяем путь к текущему скрипту (если запущен через iex, скачиваем)
        $tempScript = Join-Path $env:TEMP "install-skills.ps1"
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/usliders/skills/main/install.ps1" -OutFile $tempScript -UseBasicParsing
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`" -RepoUrl `"$RepoUrl`" -Branch `"$Branch`" -TargetDir `"$TargetDir`" -AllSkills:`$$AllSkills"
        exit 0
    }

    # Установка через winget
    Write-Info "Устанавливаю Git через winget..."
    try {
        winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            # Обновляем PATH текущей сессии
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Success "Git успешно установлен!"
                return $true
            } else {
                Write-Error "Git установлен, но не добавлен в PATH. Перезапустите PowerShell и выполните скрипт снова."
            }
        } else {
            Write-Error "Не удалось установить Git через winget (код $LASTEXITCODE). Установите вручную: https://git-scm.com/download/win"
        }
    } catch {
        Write-Error "Ошибка при запуске winget: $_`nУстановите Git вручную: https://git-scm.com/download/win"
    }
}

# Выполняем проверку Git
Ensure-Git

# ============================================================
# 2. Клонирование репозитория и получение списка скилов
# ============================================================
Write-Info "Клонируем репозиторий $RepoUrl (ветка $Branch)..."
$tempDir = Join-Path $env:TEMP "skills-$([System.IO.Path]::GetRandomFileName())"
git clone --depth 1 --branch $Branch $RepoUrl $tempDir 2>$null
if (-not (Test-Path (Join-Path $tempDir ".git"))) {
    Write-Error "Не удалось клонировать репозиторий. Проверьте интернет и URL."
}

# Определяем папку со скилами (либо корень, либо /skills)
$skillsSrc = if (Test-Path (Join-Path $tempDir "skills")) { Join-Path $tempDir "skills" } else { $tempDir }

# Собираем список доступных скилов (папки, содержащие SKILL.md)
$availableSkills = Get-ChildItem $skillsSrc -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object { $_.Name } | Sort-Object
if ($availableSkills.Count -eq 0) {
    Write-Error "В репозитории не найдено ни одного скила (отсутствуют папки с SKILL.md)."
}

Write-Info "Найдено скилов: $($availableSkills.Count)"

# ============================================================
# 3. Выбор AI-ассистента (целевой папки)
# ============================================================
if ([string]::IsNullOrEmpty($TargetDir)) {
    Write-Host ""
    Write-Host "Выберите AI-ассистента (путь для установки скилов):" -ForegroundColor "White"
    Write-Host "  1) Claude Code        → .claude\skills"
    Write-Host "  2) Cursor             → .cursor\skills"
    Write-Host "  3) Gemini CLI         → .gemini\skills"
    Write-Host "  4) Pi                 → .pi\skills"
    Write-Host "  5) Codex CLI          → .codex\skills"
    Write-Host "  6) Antigravity        → .agent\skills"
    Write-Host "  7) GitHub Copilot     → .github\skills"
    Write-Host "  8) Windsurf Cascade   → .windsurf\skills"
    Write-Host "  9) Augment Code       → .augment\skills"
    Write-Host " 10) Универсальный      → .agents\skills"
    Write-Host " 11) BoltAI             → .bolt\skills"
    Write-Host " 12) Ручной ввод пути"
    Write-Host " 13) Отмена"
    $choice = Read-Host "Ваш выбор (1-13)"

    switch ($choice) {
        "1"  { $TargetDir = ".claude\skills" }
        "2"  { $TargetDir = ".cursor\skills" }
        "3"  { $TargetDir = ".gemini\skills" }
        "4"  { $TargetDir = ".pi\skills" }
        "5"  { $TargetDir = ".codex\skills" }
        "6"  { $TargetDir = ".agent\skills" }
        "7"  { $TargetDir = ".github\skills" }
        "8"  { $TargetDir = ".windsurf\skills" }
        "9"  { $TargetDir = ".augment\skills" }
        "10" { $TargetDir = ".agents\skills" }
        "11" { $TargetDir = ".bolt\skills" }
        "12" { $TargetDir = Read-Host "Введите путь (например: .my-skills)" }
        "13" { Write-Info "Установка отменена."; Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue; exit 0 }
        default { Write-Error "Некорректный выбор" }
    }
}

# Создаём целевую папку в текущем проекте
$fullTarget = Join-Path (Get-Location) $TargetDir
New-Item -ItemType Directory -Path $fullTarget -Force | Out-Null
Write-Info "Целевая папка: $fullTarget"

# ============================================================
# 4. Выбор скилов для установки
# ============================================================
$selectedSkills = @()
if ($AllSkills) {
    $selectedSkills = $availableSkills
    Write-Success "Выбраны все скилы"
} else {
    Write-Host ""
    Write-Host "Доступные скилы:" -ForegroundColor "White"
    for ($i = 0; $i -lt $availableSkills.Count; $i++) {
        Write-Host "  $($i+1)) $($availableSkills[$i])"
    }
    $inputChoice = Read-Host "Введите номера через запятую (например: 1,3,5) или 'all' для всех"
    if ($inputChoice -eq "all") {
        $selectedSkills = $availableSkills
    } else {
        $indices = $inputChoice -split ',' | ForEach-Object { $_.Trim() }
        foreach ($idx in $indices) {
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $availableSkills.Count) {
                $selectedSkills += $availableSkills[[int]$idx - 1]
            } else {
                Write-Warning "Некорректный номер: $idx — пропускаем"
            }
        }
    }
}

if ($selectedSkills.Count -eq 0) {
    Write-Error "Не выбрано ни одного скила для установки."
}

# ============================================================
# 5. Копирование выбранных скилов
# ============================================================
Write-Success "Установка $($selectedSkills.Count) скилов в $TargetDir ..."
$copied = 0
foreach ($skill in $selectedSkills) {
    $src = Join-Path $skillsSrc $skill
    $dest = Join-Path $fullTarget $skill
    if (Test-Path $src) {
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item -Path $src -Destination $dest -Recurse -Force
        if (Test-Path (Join-Path $dest "SKILL.md")) {
            Write-Success "  ✓ $skill"
            $copied++
        } else {
            Write-Warning "  ✗ $skill — скопировано, но SKILL.md отсутствует"
        }
    } else {
        Write-Warning "  ✗ $skill — исходная папка не найдена"
    }
}

# ============================================================
# 6. Завершение
# ============================================================
Write-Host ""
Write-Success "Готово! Установлено скилов: $copied"
Write-Info "Скилы установлены в: $fullTarget"

# Очистка временных файлов
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

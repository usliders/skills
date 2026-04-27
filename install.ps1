#!/usr/bin/env pwsh
# install.ps1 - Установка скилов из usliders/skills в текущий проект

param(
    [string]$RepoUrl = "https://github.com/usliders/skills.git",
    [string]$Branch = "main",
    [string]$TargetDir = "",
    [switch]$AllSkills
)

# Цвета для вывода (работает в Windows Terminal / PSReadLine)
$InfoColor = "Cyan"
$SuccessColor = "Green"
$WarnColor = "Yellow"
$ErrorColor = "Red"

function Write-Info   { Write-Host "[INFO] $args" -ForegroundColor $InfoColor }
function Write-Success{ Write-Host "[OK]   $args" -ForegroundColor $SuccessColor }
function Write-Warning{ Write-Host "[WARN] $args" -ForegroundColor $WarnColor }
function Write-Error  { Write-Host "[ERROR] $args" -ForegroundColor $ErrorColor; exit 1 }

# Проверка наличия git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git не найден в PATH. Установите Git для Windows: https://git-scm.com/download/win"
}

# Создание временной папки
$tempDir = Join-Path $env:TEMP "skills-$([System.IO.Path]::GetRandomFileName())"
Write-Info "Клонируем репозиторий $RepoUrl (ветка $Branch)..."
git clone --depth 1 --branch $Branch $RepoUrl $tempDir 2>$null
if (-not (Test-Path (Join-Path $tempDir ".git"))) {
    Write-Error "Не удалось клонировать репозиторий. Проверьте URL и интернет."
}

# Определяем папку со скилами
$skillsSrc = if (Test-Path (Join-Path $tempDir "skills")) { Join-Path $tempDir "skills" } else { $tempDir }

# Получаем список скилов (папки с SKILL.md)
$availableSkills = Get-ChildItem $skillsSrc -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object { $_.Name } | Sort-Object
if ($availableSkills.Count -eq 0) {
    Write-Error "В репозитории не найдено ни одного скила (SKILL.md)."
}

Write-Info "Найдено скилов: $($availableSkills.Count)"

# Интерактивный выбор AI-ассистента, если TargetDir не задан
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

# Целевая папка в текущем проекте
$fullTarget = Join-Path (Get-Location) $TargetDir
New-Item -ItemType Directory -Path $fullTarget -Force | Out-Null
Write-Info "Целевая папка: $fullTarget"

# Выбор скилов для установки
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

Write-Success "Установка $($selectedSkills.Count) скилов в $TargetDir ..."
$copied = 0
foreach ($skill in $selectedSkills) {
    $src = Join-Path $skillsSrc $skill
    $dest = Join-Path $fullTarget $skill
    if (Test-Path $src) {
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
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

Write-Host ""
Write-Success "Готово! Установлено скилов: $copied"
Write-Info "Скилы установлены в: $fullTarget"

# Очистка
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

#!/usr/bin/env bash

# скрипт установки скилов с поддержкой AI-ассистентов

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

for cmd in git mktemp; do
    if ! command -v "$cmd" &> /dev/null; then
        error "Утилита '$cmd' не найдена."
    fi
done

REPO_URL="${SKILLS_REPO_URL:-https://github.com/usliders/skills.git}"
REPO_BRANCH="${SKILLS_REPO_BRANCH:-main}"

detect_ai_assistant() {
    local detected=""

    if command -v claude &> /dev/null; then
        detected="claude"
    elif command -v cursor &> /dev/null; then
        detected="cursor"
    elif command -v gemini &> /dev/null; then
        detected="gemini"
    elif command -v pi &> /dev/null; then
        detected="pi"
    elif command -v codex &> /dev/null; then
        detected="codex"
    fi

    if [ -n "$detected" ]; then
        echo -e "\n✨ Обнаружен AI-ассистент: $detected"
        read -p "Использовать его для установки? (y/n, по умолчанию y): " use_detected
        if [[ "$use_detected" != "n" && "$use_detected" != "N" ]]; then
            echo "$detected"
        fi
    fi
}

get_target_dir() {
    local assistant="$1"
    local target=""

    case "$assistant" in
        claude)
            target=".claude/skills"
            ;;
        cursor)
            target=".cursor/skills"
            ;;
        gemini)
            target=".gemini/skills"
            ;;
        pi)
            target=".pi/skills"
            ;;
        codex)
            target=".codex/skills"
            ;;
        antigravity)
            target=".agent/skills"
            ;;
        copilot)
            target=".github/skills"
            ;;
        windsurf)
            target=".windsurf/skills"
            ;;
        augment)
            target=".augment/skills"
            ;;
        generic)
            target=".agents/skills"
            ;;
        bolt)
            target=".bolt/skills"
            ;;
        *)
            info "Неизвестный ассистент: $assistant"
            read -p "Введите путь для установки скилов (например: .my-skills): " target
            ;;
    esac

    echo "$target"
}

function show_menu() {
    echo ""
    echo "🤖 Выберите AI-ассистента (путь для установки скилов):"
    echo "  1) Claude Code        →  .claude/skills"
    echo "  2) Cursor             →  .cursor/skills"
    echo "  3) Gemini CLI         →  .gemini/skills"
    echo "  4) Pi                 →  .pi/skills"
    echo "  5) Codex CLI          →  .codex/skills"
    echo "  6) Antigravity        →  .agent/skills"
    echo "  7) GitHub Copilot     →  .github/skills"
    echo "  8) Windsurf Cascade   →  .windsurf/skills"
    echo "  9) Augment Code       →  .augment/skills"
    echo " 10) Универсальный      →  .agents/skills"
    echo " 11) BoltAI             →  .bolt/skills"
    echo " 12) Ручной ввод пути"
    echo " 13) Отмена"

    read -p "Ваш выбор (1-13): " choice
    echo ""

    assistant=""
    case "$choice" in
        1)  assistant="claude";;
        2)  assistant="cursor";;
        3)  assistant="gemini";;
        4)  assistant="pi";;
        5)  assistant="codex";;
        6)  assistant="antigravity";;
        7)  assistant="copilot";;
        8)  assistant="windsurf";;
        9)  assistant="augment";;
        10) assistant="generic";;
        11) assistant="bolt";;
        12) assistant="custom";;
        13) info "Установка отменена."; exit 0;;
        *)  error "Некорректный выбор. Запустите скрипт заново.";;
    esac

    if [ "$assistant" = "custom" ]; then
        read -p "📁 Введите путь для установки скилов: " MANUAL_DIR
        TARGET_DIR="$MANUAL_DIR"
    else
        TARGET_DIR=$(get_target_dir "$assistant")
    fi

    info "📂 Целевая директория: $TARGET_DIR"
    read -p "Продолжить установку в эту папку? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "Установка отменена."
        exit 0
    fi

    select_skills "$TARGET_DIR"
}

select_skills() {
    local target_dir="$1"

    TEMP_DIR=$(mktemp -d -t skills-install-XXXXXX)
    trap "rm -rf $TEMP_DIR" EXIT

    info "Клонирую репозиторий $REPO_URL ..."
    if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        error "Не удалось клонировать репозиторий"
    fi

    if [ -d "$TEMP_DIR/skills" ]; then
        SKILLS_SRC="$TEMP_DIR/skills"
    elif [ -d "$TEMP_DIR" ]; then
        SKILLS_SRC="$TEMP_DIR"
    else
        error "Папка скилов не найдена"
    fi

    mapfile -t available_skills < <(find "$SKILLS_SRC" -maxdepth 1 -type d | tail -n +2 | while read d; do [ -f "$d/SKILL.md" ] && basename "$d"; done | sort)
    if [ ${#available_skills[@]} -eq 0 ]; then
        error "В репозитории не найдено ни одного скила (папок с SKILL.md)."
    fi

    info "📋 Найдено скилов: ${#available_skills[@]}"

    while true; do
        echo ""
        echo "Выберите действие:"
        echo "  1) Установить ВСЕ скилы"
        echo "  2) Выбрать скилы по номерам (например: 1,3,5)"
        echo "  3) Выбрать диапазон (например: 1-5)"
        echo "  4) Отмена"
        read -p "Ваш выбор (1-4): " action

        local selected=()
        case "$action" in
            1)
                selected=("${available_skills[@]}")
                break
                ;;
            2)
                echo "Доступные скилы:"
                for i in "${!available_skills[@]}"; do
                    printf "  %3d) %s\n" $((i+1)) "${available_skills[$i]}"
                done
                read -p "Введите номера через запятую (например: 1,3,5): " nums
                IFS=',' read -ra indices <<< "$nums"
                for idx in "${indices[@]}"; do
                    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#available_skills[@]}" ]; then
                        selected+=("${available_skills[$((idx-1))]}")
                    else
                        warn "Некорректный номер: $idx — пропускаем"
                    fi
                done
                break
                ;;
            3)
                echo "Доступные скилы:"
                for i in "${!available_skills[@]}"; do
                    printf "  %3d) %s\n" $((i+1)) "${available_skills[$i]}"
                done
                read -p "Введите диапазон (например: 1-5 или 2-8): " range
                if [[ "$range" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    start=${BASH_REMATCH[1]}
                    end=${BASH_REMATCH[2]}
                    if [ "$start" -ge 1 ] && [ "$end" -le "${#available_skills[@]}" ] && [ "$start" -le "$end" ]; then
                        for ((i=start; i<=end; i++)); do
                            selected+=("${available_skills[$((i-1))]}")
                        done
                    else
                        error "Диапазон выходит за границы (1..${#available_skills[@]})"
                    fi
                else
                    error "Неверный формат диапазона"
                fi
                break
                ;;
            4)
                info "Установка отменена."
                exit 0
                ;;
            *)
                warn "Некорректный выбор. Попробуйте снова."
                ;;
        esac
    done

    if [ ${#selected[@]} -eq 0 ]; then
        error "Не выбрано ни одного скила для установки."
    fi

    mkdir -p "$target_dir"

    success "Установка ${#selected[@]} скилов в $target_dir..."
    local copied=0
    for skill in "${selected[@]}"; do
        src_path="$SKILLS_SRC/$skill"
        dest_path="$target_dir/$skill"
        if [ -d "$src_path" ]; then
            [ -d "$dest_path" ] && rm -rf "$dest_path"
            cp -r "$src_path" "$dest_path"
            [ -f "$dest_path/SKILL.md" ] && { success "  ✓ $skill"; ((copied++)); } || warn "  ✗ $skill — нет SKILL.md"
        else
            warn "  ✗ $skill — исходная папка не найдена"
        fi
    done

    echo ""
    success "✅ Готово! Установлено скилов: $copied"
    info "📁 Скилы установлены в: $(pwd)/$target_dir"
}

main() {
    info "🔧 Установщик скилов для AI-ассистентов"
    info "Репозиторий: $REPO_URL (ветка $REPO_BRANCH)"

    detected=$(detect_ai_assistant)
    if [ -n "$detected" ]; then
        TARGET_DIR=$(get_target_dir "$detected")
        info "📂 Автоматически выбрана директория для $detected: $TARGET_DIR"
        read -p "Использовать эту директорию? (y/n, по умолчанию y): " use_auto
        if [[ "$use_auto" != "n" && "$use_auto" != "N" ]]; then
            select_skills "$TARGET_DIR"
        else
            show_menu
        fi
    else
        show_menu
    fi
}

if ! main "$@"; then
    error "Произошла ошибка во время выполнения. Смотрите сообщения выше."
fi
# AI Skills Collection / Коллекция скилов для AI-ассистентов

[![GitHub license](https://img.shields.io/github/license/usliders/skills)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/usliders/skills)](https://github.com/usliders/skills/stargazers)

Набор готовых инструкций (скилов) для AI-ассистентов: Claude Code, Cursor, Gemini, GitHub Copilot, Pi, Windsurf и других.  
A collection of ready-to-use skills for AI assistants: Claude Code, Cursor, Gemini, GitHub Copilot, Pi, Windsurf and others.

## 🚀 Быстрый старт / Quick Start

### Windows (PowerShell)

Одна команда — всё само установится (Git будет найден или предложен к установке):

```powershell
iex (iwr -Uri 'https://raw.githubusercontent.com/usliders/skills/main/install.ps1' -UseBasicParsing).Content
```

### Linux / macOS / Git Bash (WSL)

```bash
bash <(curl -s https://raw.githubusercontent.com/usliders/skills/main/install.sh)
```

### Альтернатива для Windows (cmd)

```cmd
curl -sL https://raw.githubusercontent.com/usliders/skills/main/install-ps.bat -o %temp%\install.bat && %temp%\install.bat
```

📖 **Что делает скрипт? / What does the script do?**

- Проверяет наличие Git (при необходимости находит его в стандартных папках или предлагает установить через winget)
- Клонирует репозиторий usliders/skills во временную папку
- Показывает список доступных скилов (все папки с файлом SKILL.md)
- Предлагает выбрать AI-ассистента — от этого зависит целевая папка (.claude/skills, .cursor/skills и т.д.)
- Копирует выбранные скилы в текущий проект
- Автоматически удаляет временные файлы

After installation, your AI assistant can use these skills (e.g. /skills in Claude Code).

## 🛠 Ручная установка / Manual installation

```bash
git clone https://github.com/usliders/skills.git
cd skills
# Copy desired folders (e.g. to-prd) into your AI assistant's target directory
```

| AI Assistant | Default folder |
|-------------|---------------|
| Claude Code | .claude/skills |
| Cursor | .cursor/skills |
| Gemini CLI | .gemini/skills |
| Pi | .pi/skills |
| Codex CLI | .codex/skills |
| Antigravity | .agent/skills |
| GitHub Copilot | .github/skills |
| Windsurf Cascade | .windsurf/skills |
| Augment Code | .augment/skills |
| BoltAI | .bolt/skills |
| Universal | .agents/skills |

## 📚 Доступные скилы / Available skills

- **to-prd** — превращение идеи в PRD / product requirements
- **tdd** — Test-Driven Development пошаговые инструкции
- **git-guardrails-claude-code** — безопасная работа с Git / safe Git usage
- **refactoring** — рефакторинг / refactoring
- **debugging** — отладка / debugging
- и другие / and more

## ❓ Частые вопросы / FAQ

### Нужно ли платить? / Is paid?
Нет, MIT license. / No, MIT license.

### Как обновить? / How to update?
Запустите скрипт повторно. / Run the script again.

### Могу ли добавить свои скилы? / Can I add my own skills?
Да, форкните репозиторий. / Yes, fork the repo.

### Работает с GPT-4 / Copilot Chat?
Skills designed for agents supporting SKILL.md. For plain ChatGPT you can copy instructions manually.

## 🔗 Ссылки / Links

- Original source: [mattpocock/skills](https://github.com/mattpocock/skills)
- Claude Code docs: [anthropic.com/claude-code](https://www.anthropic.com/claude-code)
- Cursor docs: [cursor.sh](https://cursor.sh)

## 📄 Лицензия / License

MIT © usliders

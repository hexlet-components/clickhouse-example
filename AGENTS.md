# AGENTS.md

Репозиторий создан из шаблона `hexlet-components/component-template`. Шаблон ставит общий слой проверок из [dev-quality-gates](https://github.com/mokevnin/dev-quality-gates): mise, hk, commitlint, rumdl, typos, lychee, jactionlint и betterleaks. Проверки под стек репозитория шаблон не знает, их добавляет первая настройка.

## Первая настройка

Пока этот раздел в файле, репозиторий не настроен. Задача `test` падает, и CI красный.

1. Определи стек по задаче компонента.
2. Пройди [adopt.md](https://raw.githubusercontent.com/mokevnin/dev-quality-gates/main/docs/adopt.md) для этого стека. Общий слой уже стоит, его не трогай. Новые инструменты закрепляются в `mise.toml`, линтеры и форматтеры стека становятся шагами `hk.pkl`, и их запускает `mise run check`. OSV-Scanner добавляется вместе с первым lock-файлом.
3. Фронтенд берёт CSS по `docs/css-frameworks-migration.md` из hexlet-exercise-kit. С React это Vite и Mantine, без React последний Tailwind.
4. Задачи проекта живут в `mise.toml`, а `Makefile` только проксирует `make <задача>` в `mise run <задача>`. Поставь установку зависимостей стека в `setup` перед `hk install` и заполни `test`. Компонент с публикацией получает выкладку в `.github/workflows/main.yml`, actions в ней закрепляются по SHA.
5. Добавь экосистему пакетов стека в `.github/dependabot.yml`.
6. Доведи `README.md` по его заготовке. Замени `component-template` именем репозитория, в том числе в бейджах и в `utm_campaign` шапки и строки про команду Хекслета. Заголовок в шапке назови по назначению компонента, опиши компонент и для какого курса, проекта или программы он нужен, удали цитату про шаблон. Шапка с вордмарком Хекслета и строка про команду остаются, так оформлены README в `Hexlet/ru-instructions` и `hexlet-components/system-design-workshops`.

Настройка закончена, когда `mise run setup`, `mise run check` и `mise run test` проходят, каждый новый шаг проверки один раз упал на подложенном нарушении, а этот раздел удалён из файла.

<div align="center">

<a href="https://hexlet.io/?utm_source=github&utm_medium=link&utm_campaign=component-template">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Hexlet/brand-assets/master/images/svg/hexlet_wordmark_white_rus.svg">
        <img src="https://raw.githubusercontent.com/Hexlet/brand-assets/master/images/svg/hexlet_wordmark_primary_rus.svg" alt="Хекслет" height="64">
    </picture>
</a>

# component-template

[![CI](https://github.com/hexlet-components/component-template/actions/workflows/main.yml/badge.svg)](https://github.com/hexlet-components/component-template/actions/workflows/main.yml)
[![Check](https://github.com/hexlet-components/component-template/actions/workflows/check.yml/badge.svg)](https://github.com/hexlet-components/component-template/actions/workflows/check.yml)

</div>

Компонент создаёт и поддерживает команда [Хекслета](https://hexlet.io/?utm_source=github&utm_medium=link&utm_campaign=component-template), образовательного проекта.

> Шаблон репозиториев hexlet-components. Новый репозиторий создаётся командой ниже, а после клона его настраивает раздел «Первая настройка» в [AGENTS.md](AGENTS.md). Настройка заменяет `component-template` в этом файле именем репозитория, заполняет разделы и удаляет эту цитату.
>
> ```sh
> gh repo create hexlet-components/<имя> --public --template hexlet-components/component-template --description "<что это и для какого курса>"
> ```

Что это и для какого курса, проекта или программы Хекслета. Одним-двумя абзацами: кто пользуется компонентом (студент в уроке, проверка практики, стенд проекта) и что сломается у них, если его поменять.

## Запуск

```sh
mise run setup
mise run test
```

`make <задача>` вызывает ту же задачу mise.

## Проверки

`mise run check` гоняет тот же набор, что CI: разметку, опечатки, ссылки, workflows и проверки стека.

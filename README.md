<div align="center">

<a href="https://hexlet.io/?utm_source=github&utm_medium=link&utm_campaign=clickhouse-example">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Hexlet/brand-assets/master/images/svg/hexlet_wordmark_white_rus.svg">
        <img src="https://raw.githubusercontent.com/Hexlet/brand-assets/master/images/svg/hexlet_wordmark_primary_rus.svg" alt="Хекслет" height="64">
    </picture>
</a>

# Учебная база ClickHouse

[![CI](https://github.com/hexlet-components/clickhouse-example/actions/workflows/main.yml/badge.svg)](https://github.com/hexlet-components/clickhouse-example/actions/workflows/main.yml)
[![Check](https://github.com/hexlet-components/clickhouse-example/actions/workflows/check.yml/badge.svg)](https://github.com/hexlet-components/clickhouse-example/actions/workflows/check.yml)

</div>

Компонент создаёт и поддерживает команда [Хекслета](https://hexlet.io/?utm_source=github&utm_medium=link&utm_campaign=clickhouse-example), образовательного проекта.

Здесь лежит база доски объявлений для курса [ClickHouse](https://ru.hexlet.io/courses/clickhouse) и примеры запросов к ней. В уроках курса каждый пример создаёт свою маленькую таблицу, а здесь данных миллионы строк. На таком объёме видно то, ради чего ClickHouse выбирают, то есть сжатие столбцов, отсечение гранул по ключу сортировки и разница в прочитанных строках между двумя версиями запроса.

Данные строятся генератором прямо на сервере, файлов с данными в репозитории нет. Генератор опирается на хеши номера строки, поэтому при одном масштабе каждая загрузка даёт те же строки и те же ответы.

## Что в базе

Все таблицы лежат в базе `board`. Числа строк даны для масштаба по умолчанию.

| Таблица | Строк | Что хранит |
| --- | --- | --- |
| `sellers` | 50 тысяч | Продавцы, частные лица и компании из десяти городов |
| `ads` | 500 тысяч | Снимок каталога, последняя цена и статус объявления, фотографии и метки |
| `ad_versions` | 1,25 миллиона | История изменений цены и статуса, от одной до четырёх версий на объявление |
| `events` | 10 миллионов | Просмотры, добавления в избранное и обращения к продавцу за лето 2026 года |
| `incoming_ads` | 50 тысяч | Входящие сообщения о новых объявлениях в виде JSON-текста |

В данных есть закономерности, которые находятся запросами. Объявление с фотографиями продаётся чаще, компании держат почти половину объявлений, к продавцам автомобилей обращаются в два с половиной раза чаще, чем в других категориях, а вечером посетителей больше, чем ночью. Каждое двадцатое входящее сообщение приходит без цены, каждое пятидесятое обрезано.

Загрузка занимает несколько секунд и около 220 МиБ на диске. Масштаб меняет переменная `SCALE`, при `SCALE=5` событий будет 50 миллионов.

## Запуск с установленным ClickHouse

Сервер ставится по [инструкции](https://github.com/Hexlet/ru-instructions/blob/main/clickhouse.md). Задачи запускаются через [mise](https://mise.jdx.dev), а `make <задача>` вызывает ту же задачу.

```sh
git clone https://github.com/hexlet-components/clickhouse-example.git
cd clickhouse-example
make load
make examples
```

Повторный `make load` пересоздаёт базу `board` целиком. Масштаб задаётся так.

```sh
SCALE=5 make load
```

## Запуск в Docker

Сервер из `compose.yaml` запускается той же версии, на которой проверен курс. Клиент внутри контейнера задаёт переменная `CLICKHOUSE_CLIENT`.

```sh
export CLICKHOUSE_CLIENT="docker compose exec -T clickhouse clickhouse-client"
make up
make load
make examples
```

Подключиться к базе для своих запросов можно так.

```sh
docker compose exec clickhouse clickhouse-client --database board
```

`make down` останавливает сервер и удаляет его данные.

## Примеры

Каждый файл в `examples/` разбирает одну тему курса, а комментарии над запросами объясняют, что показывает результат. Примеры только читают базу `board`. Файлы, которым нужны свои таблицы, создают их в базе `board_lab` и удаляют её в конце.

| Файл | Тема |
| --- | --- |
| `01-catalog.sql` | Распределение объявлений и цен, медиана и частые значения |
| `02-activity.sql` | Показатели по неделям и часам, конверсия в обращение, скользящая сумма |
| `03-joins.sql` | Соединение событий с каталогом и продавцами, поиск объявлений без просмотров |
| `04-arrays.sql` | `ARRAY JOIN` по меткам, пустые массивы, функции над массивами |
| `05-json.sql` | Разбор JSON-текста, отбраковка сообщений, тип `JSON` |
| `06-versions.sql` | История версий, `argMax`, `ReplacingMergeTree` до и после слияния |
| `07-materialized-views.sql` | Агрегатные состояния и раскладка JSON по таблицам через материализованные представления |
| `08-storage.sql` | Сжатие по столбцам, части и партиции, `String` против `LowCardinality` |
| `09-sorting-key.sql` | Ключ сортировки и число прочитанных гранул в `EXPLAIN indexes = 1` |
| `10-query-analysis.sql` | Сравнение двух версий запроса по `system.query_log`, план выполнения |

Один файл выполняется так.

```sh
clickhouse client --multiquery < examples/09-sorting-key.sql
```

## Проверки

`make test` загружает базу в малом масштабе и выполняет все примеры, на ошибке в любом запросе задача падает. `make check` проверяет разметку, опечатки, ссылки и workflows. CI на GitHub запускает обе задачи на сервере из `compose.yaml`.

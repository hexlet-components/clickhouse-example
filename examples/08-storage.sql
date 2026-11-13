-- Устройство хранения. ClickHouse хранит каждый столбец отдельно и сжимает
-- его, а таблица MergeTree состоит из частей, которые фоновый процесс
-- сливает в более крупные.

-- Размер таблиц на диске и степень сжатия.
SELECT
    table,
    sum(rows) AS rows,
    formatReadableSize(sum(data_uncompressed_bytes)) AS uncompressed,
    formatReadableSize(sum(data_compressed_bytes)) AS compressed,
    round(sum(data_uncompressed_bytes) / sum(data_compressed_bytes), 1) AS ratio
FROM system.parts
WHERE database = 'board' AND active
GROUP BY table
ORDER BY sum(data_compressed_bytes) DESC;

-- Сжатие по столбцам таблицы событий. Столбцы из ключа сортировки и столбцы
-- LowCardinality с повторяющимися значениями сжимаются в десятки раз, а
-- идентификаторы событий почти не сжимаются.
SELECT
    name,
    type,
    formatReadableSize(data_compressed_bytes) AS compressed,
    round(data_uncompressed_bytes / data_compressed_bytes, 1) AS ratio
FROM system.columns
WHERE database = 'board' AND table = 'events'
ORDER BY data_compressed_bytes DESC;

-- Части таблицы событий. Таблица разбита на партиции по месяцам, и внутри
-- каждой партиции лежат свои части.
SELECT
    partition,
    count() AS parts,
    sum(rows) AS rows,
    sum(marks) AS marks
FROM system.parts
WHERE database = 'board' AND table = 'events' AND active
GROUP BY partition
ORDER BY partition;

-- Строка против LowCardinality. Копируем город в два столбца разных типов и
-- сравниваем их размер.
CREATE DATABASE IF NOT EXISTS board_lab;

DROP TABLE IF EXISTS board_lab.city_types;

CREATE TABLE board_lab.city_types
(
    event_id UInt64,
    city_string String,
    city_low LowCardinality(String)
)
ENGINE = MergeTree
ORDER BY event_id;

INSERT INTO board_lab.city_types
SELECT
    event_id,
    city,
    city
FROM board.events;

SELECT
    name,
    formatReadableSize(data_uncompressed_bytes) AS uncompressed,
    formatReadableSize(data_compressed_bytes) AS compressed
FROM system.columns
WHERE database = 'board_lab' AND table = 'city_types' AND name LIKE 'city%';

DROP DATABASE board_lab;

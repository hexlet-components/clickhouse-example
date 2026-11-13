-- Ключ сортировки. Строки части лежат в порядке ключа, а разреженный индекс
-- хранит значение ключа для каждой гранулы из 8192 строк. Запрос с условием
-- на начало ключа читает только подходящие гранулы.

-- Таблица событий отсортирована по (event_type, category, event_time).
-- Условие на тип и категорию попадает в начало ключа, и в строке Granules
-- видно, что индекс оставил два десятка гранул из тысячи с лишним.
EXPLAIN indexes = 1
SELECT uniq(visitor_id)
FROM board.events
WHERE event_type = 'contact' AND category = 'Авто';

-- Условие на объявление в ключ не входит, и запрос читает все гранулы.
EXPLAIN indexes = 1
SELECT uniq(visitor_id)
FROM board.events
WHERE ad_id = 42;

-- Копия событий с ключом по объявлению. Тот же запрос по ad_id в ней читает
-- несколько гранул.
CREATE DATABASE IF NOT EXISTS board_lab;

DROP TABLE IF EXISTS board_lab.events_by_ad;

CREATE TABLE board_lab.events_by_ad AS board.events
ENGINE = MergeTree
ORDER BY (ad_id, event_time);

INSERT INTO board_lab.events_by_ad
SELECT *
FROM board.events;

EXPLAIN indexes = 1
SELECT uniq(visitor_id)
FROM board_lab.events_by_ad
WHERE ad_id = 42;

-- Обе таблицы дают одинаковый ответ.
SELECT
    (SELECT count() FROM board.events WHERE ad_id = 42) AS by_event_type,
    (SELECT count() FROM board_lab.events_by_ad WHERE ad_id = 42) AS by_ad;

-- Ключ влияет и на сжатие. Подряд идущие одинаковые значения сжимаются
-- лучше, поэтому столбец из начала ключа занимает в двух таблицах разный
-- объём.
SELECT
    table,
    name,
    formatReadableSize(data_compressed_bytes) AS compressed
FROM system.columns
WHERE
    (database = 'board' AND table = 'events' OR database = 'board_lab' AND table = 'events_by_ad')
    AND name IN ('event_type', 'ad_id')
ORDER BY name, table;

DROP DATABASE board_lab;

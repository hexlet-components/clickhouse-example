-- Материализованное представление. Оно срабатывает на каждую вставку в
-- исходную таблицу и пишет результат своего запроса в целевую таблицу.

CREATE DATABASE IF NOT EXISTS board_lab;

DROP TABLE IF EXISTS board_lab.daily_stats_mv;

DROP TABLE IF EXISTS board_lab.daily_stats;

DROP TABLE IF EXISTS board_lab.events;

DROP TABLE IF EXISTS board_lab.incoming_ads;

DROP TABLE IF EXISTS board_lab.parsed_ads;

DROP TABLE IF EXISTS board_lab.rejected_ads;

DROP TABLE IF EXISTS board_lab.parse_ads_mv;

DROP TABLE IF EXISTS board_lab.reject_ads_mv;

-- Дневная статистика по категориям. Целевая таблица хранит состояния
-- агрегатных функций, поэтому строки разных вставок можно объединить без
-- пересчёта исходных событий.
CREATE TABLE board_lab.events AS board.events;

CREATE TABLE board_lab.daily_stats
(
    day Date,
    category LowCardinality(String),
    views AggregateFunction(count),
    contacts AggregateFunction(countIf, UInt8),
    visitors AggregateFunction(uniq, UInt64)
)
ENGINE = AggregatingMergeTree
ORDER BY (day, category);

CREATE MATERIALIZED VIEW board_lab.daily_stats_mv TO board_lab.daily_stats AS
SELECT
    toDate(event_time) AS day,
    category,
    countState() AS views,
    countIfState(event_type = 'contact') AS contacts,
    uniqState(visitor_id) AS visitors
FROM board_lab.events
GROUP BY day, category;

-- Представление видит только новые вставки. События июня вставляем двумя
-- пакетами, и обе вставки попадают в статистику.
INSERT INTO board_lab.events
SELECT *
FROM board.events
WHERE event_time < '2026-06-15';

INSERT INTO board_lab.events
SELECT *
FROM board.events
WHERE event_time >= '2026-06-15' AND event_time < '2026-07-01';

-- Чтение статистики. Функции с суффиксом Merge объединяют состояния, которые
-- пришли из разных вставок.
SELECT
    category,
    countMerge(views) AS events,
    countIfMerge(contacts) AS contacts,
    uniqMerge(visitors) AS visitors
FROM board_lab.daily_stats
WHERE day BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY category
ORDER BY events DESC;

-- Тот же расчёт по исходным событиям даёт те же числа событий и обращений.
SELECT
    category,
    count() AS events,
    countIf(event_type = 'contact') AS contacts
FROM board_lab.events
GROUP BY category
ORDER BY events DESC;

-- Раскладка JSON по таблицам. Одно представление разбирает годные сообщения
-- в типизированную таблицу, второе складывает отбракованные отдельно.
CREATE TABLE board_lab.incoming_ads AS board.incoming_ads;

CREATE TABLE board_lab.parsed_ads
(
    ad_id UInt64,
    category LowCardinality(String),
    seller_id UInt32,
    price UInt32,
    photos Array(String),
    received_at DateTime('Europe/Moscow')
)
ENGINE = MergeTree
ORDER BY (category, ad_id);

CREATE TABLE board_lab.rejected_ads
(
    received_at DateTime('Europe/Moscow'),
    reason LowCardinality(String),
    payload String
)
ENGINE = MergeTree
ORDER BY received_at;

CREATE MATERIALIZED VIEW board_lab.parse_ads_mv TO board_lab.parsed_ads AS
SELECT
    JSONExtractUInt(payload, 'ad_id') AS ad_id,
    JSONExtractString(payload, 'category') AS category,
    toUInt32(JSONExtractUInt(payload, 'seller', 'id')) AS seller_id,
    toUInt32(JSONExtractUInt(payload, 'price')) AS price,
    JSONExtract(payload, 'photos', 'Array(String)') AS photos,
    received_at
FROM board_lab.incoming_ads
WHERE isValidJSON(payload) AND JSONHas(payload, 'price');

CREATE MATERIALIZED VIEW board_lab.reject_ads_mv TO board_lab.rejected_ads AS
SELECT
    received_at,
    if(isValidJSON(payload), 'нет цены', 'битый JSON') AS reason,
    payload
FROM board_lab.incoming_ads
WHERE NOT (isValidJSON(payload) AND JSONHas(payload, 'price'));

INSERT INTO board_lab.incoming_ads
SELECT *
FROM board.incoming_ads;

-- Каждое сообщение попало ровно в одну из двух таблиц.
SELECT
    (SELECT count() FROM board_lab.incoming_ads) AS incoming,
    (SELECT count() FROM board_lab.parsed_ads) AS parsed,
    (SELECT count() FROM board_lab.rejected_ads) AS rejected;

SELECT
    reason,
    count() AS messages
FROM board_lab.rejected_ads
GROUP BY reason;

DROP DATABASE board_lab;

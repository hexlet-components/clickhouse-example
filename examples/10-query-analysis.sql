-- Анализ запроса. Журнал system.query_log хранит для каждого запроса число
-- прочитанных строк и байтов, время и память, поэтому две версии запроса
-- сравниваются по фактам.

-- Два запроса с одинаковым ответом, просмотры по дням за август. Первый
-- превращает время в строку, и ClickHouse не может сопоставить условие с
-- партициями и ключом. Второй задаёт диапазон по самому столбцу, и запрос
-- читает только августовскую партицию.
SELECT
    toDate(event_time) AS day,
    count() AS events
FROM board.events
WHERE formatDateTime(event_time, '%Y-%m') = '2026-08'
GROUP BY day
ORDER BY day
FORMAT Null
SETTINGS use_query_cache = 0, log_comment = 'clickhouse-example: время строкой';

SELECT
    toDate(event_time) AS day,
    count() AS events
FROM board.events
WHERE event_time >= '2026-08-01' AND event_time < '2026-09-01'
GROUP BY day
ORDER BY day
FORMAT Null
SETTINGS use_query_cache = 0, log_comment = 'clickhouse-example: диапазон времени';

-- Журнал запросов пишется на диск пакетами, SYSTEM FLUSH LOGS дописывает
-- накопленное сразу.
SYSTEM FLUSH LOGS;

SELECT
    log_comment,
    read_rows,
    formatReadableSize(read_bytes) AS read,
    query_duration_ms,
    formatReadableSize(memory_usage) AS memory
FROM system.query_log
WHERE
    type = 'QueryFinish'
    AND log_comment LIKE 'clickhouse-example: %'
    AND event_time > now() - INTERVAL 10 MINUTE
ORDER BY event_time DESC
LIMIT 2;

-- План выполнения. EXPLAIN PLAN показывает шаги запроса снизу вверх, от
-- чтения таблицы до итоговой проекции.
EXPLAIN PLAN
SELECT
    category,
    count() AS contacts
FROM board.events
WHERE event_type = 'contact'
GROUP BY category;

-- Отсечение партиций в плане. Строка Parts в разделе Partition показывает,
-- сколько частей осталось после условия на время.
EXPLAIN indexes = 1
SELECT uniq(visitor_id)
FROM board.events
WHERE event_time >= '2026-08-01' AND event_time < '2026-09-01';

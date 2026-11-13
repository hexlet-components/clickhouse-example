-- Активность посетителей за лето. Таблица events хранит каждое событие
-- отдельной строкой, а показатели считаются группировкой по времени.

-- Просмотры, обращения и уникальные посетители по неделям. uniq считает
-- посетителей приближённо и тратит на это мало памяти, uniqExact точен,
-- но хранит все идентификаторы.
SELECT
    toMonday(event_time) AS week,
    countIf(event_type = 'view') AS views,
    countIf(event_type = 'contact') AS contacts,
    uniq(visitor_id) AS visitors,
    uniqExact(visitor_id) AS visitors_exact
FROM board.events
GROUP BY week
ORDER BY week;

-- Активность по часам суток по московскому времени. Столбец event_time
-- объявлен с часовым поясом Europe/Moscow, поэтому toHour возвращает
-- московский час.
SELECT
    toHour(event_time) AS hour,
    count() AS events,
    bar(events, 0, max(events) OVER (), 40) AS chart
FROM board.events
GROUP BY hour
ORDER BY hour;

-- Конверсия просмотра в обращение по категориям. Обращение это главный
-- результат для продавца, и в категории «Авто» к нему приходят чаще.
SELECT
    category,
    countIf(event_type = 'view') AS views,
    countIf(event_type = 'contact') AS contacts,
    round(contacts / views * 100, 2) AS contact_rate_percent
FROM board.events
GROUP BY category
ORDER BY contact_rate_percent DESC;

-- Скользящая сумма обращений за семь дней. Оконная функция идёт поверх
-- дневных итогов, поэтому сначала строится группировка по дням.
SELECT
    day,
    contacts,
    sum(contacts) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS contacts_7d
FROM
(
    SELECT
        toDate(event_time) AS day,
        countIf(event_type = 'contact') AS contacts
    FROM board.events
    GROUP BY day
)
ORDER BY day
LIMIT 14;

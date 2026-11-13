-- Соединение таблиц. В ClickHouse правая таблица JOIN загружается в память,
-- поэтому справа ставят меньшую таблицу или заранее сгруппированный результат.

-- Продавцы с наибольшим числом обращений. События сначала сводятся к одной
-- строке на объявление, и только потом соединяются с каталогом и продавцами.
SELECT
    s.seller_id,
    s.name,
    s.city,
    sum(e.contacts) AS contacts,
    count() AS ads_with_contacts
FROM
(
    SELECT
        ad_id,
        count() AS contacts
    FROM board.events
    WHERE event_type = 'contact'
    GROUP BY ad_id
) AS e
INNER JOIN board.ads AS a ON e.ad_id = a.ad_id
INNER JOIN board.sellers AS s ON a.seller_id = s.seller_id
GROUP BY s.seller_id, s.name, s.city
ORDER BY contacts DESC
LIMIT 10;

-- Компании и частные продавцы. Сравниваем, сколько объявлений у продавца
-- в среднем и какая доля из них продана.
SELECT
    s.is_company,
    uniqExact(s.seller_id) AS sellers,
    count() AS ads,
    round(ads / sellers, 1) AS ads_per_seller,
    round(countIf(a.status = 'sold') / ads * 100, 1) AS sold_percent
FROM board.ads AS a
INNER JOIN board.sellers AS s ON a.seller_id = s.seller_id
GROUP BY s.is_company;

-- Объявления, которые никто не открыл. LEFT ANTI JOIN оставляет строки
-- левой таблицы, для которых справа не нашлось пары.
SELECT
    a.category,
    count() AS ads_without_views
FROM board.ads AS a
LEFT ANTI JOIN
(
    SELECT DISTINCT ad_id
    FROM board.events
) AS e ON a.ad_id = e.ad_id
GROUP BY a.category
ORDER BY ads_without_views DESC;

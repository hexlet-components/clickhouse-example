-- Входящие JSON-сообщения. Таблица incoming_ads хранит документ целиком
-- строкой, и поля из него достаются при чтении.

-- Разбор полей функциями JSONExtract. Тип результата задаётся явно, а у
-- отсутствующего поля функция возвращает значение по умолчанию этого типа.
SELECT
    JSONExtractUInt(payload, 'ad_id') AS ad_id,
    JSONExtractString(payload, 'category') AS category,
    JSONExtractUInt(payload, 'seller', 'id') AS seller_id,
    JSONExtract(payload, 'price', 'Nullable(UInt32)') AS price,
    JSONLength(payload, 'photos') AS photos
FROM board.incoming_ads
ORDER BY received_at
LIMIT 5;

-- Проверка сообщений. isValidJSON находит обрезанные документы, а
-- JSONHas отличает отсутствующую цену от нулевой.
SELECT
    multiIf(
        NOT isValidJSON(payload), 'битый JSON',
        NOT JSONHas(payload, 'price'), 'нет цены',
        'годное'
    ) AS verdict,
    count() AS messages
FROM board.incoming_ads
GROUP BY verdict
ORDER BY messages DESC;

-- Тип JSON. После приведения к нему пути читаются через точку, а набор
-- характеристик может отличаться от категории к категории.
SELECT
    doc.category::String AS category,
    doc.attributes.brand::String AS brand,
    count() AS messages
FROM
(
    SELECT payload::JSON AS doc
    FROM board.incoming_ads
    WHERE isValidJSON(payload)
)
WHERE category IN ('Авто', 'Электроника')
GROUP BY category, brand
ORDER BY category, messages DESC;

-- Пробег автомобилей по году выпуска. Значение пути в типе JSON хранит свой
-- тип, поэтому для арифметики его приводят явно.
SELECT
    doc.attributes.year::UInt16 AS year,
    count() AS cars,
    round(avg(doc.attributes.mileage_km::UInt32)) AS avg_mileage_km
FROM
(
    SELECT payload::JSON AS doc
    FROM board.incoming_ads
    WHERE isValidJSON(payload) AND JSONExtractString(payload, 'category') = 'Авто'
)
GROUP BY year
ORDER BY year;

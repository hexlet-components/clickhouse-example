-- Каталог объявлений. Сколько предложений в каждой категории, какие цены
-- типичны и где продают больше всего.

-- Активные объявления по категориям и медианная цена. Медиана устойчива к
-- редким дорогим лотам, поэтому рядом со средней она показывает, насколько
-- распределение цен вытянуто вправо.
SELECT
    category,
    count() AS ads,
    round(avg(price)) AS avg_price,
    quantileExact(0.5)(price) AS median_price
FROM board.ads
WHERE status = 'published'
GROUP BY category
ORDER BY ads DESC;

-- Доля проданных объявлений по городам. countIf считает строки с условием
-- в том же проходе по таблице, отдельный подзапрос на каждый статус не нужен.
SELECT
    city,
    count() AS ads,
    countIf(status = 'sold') AS sold,
    round(sold / ads * 100, 1) AS sold_percent
FROM board.ads
GROUP BY city
ORDER BY ads DESC;

-- Пять самых частых названий в каждой категории. topK возвращает
-- приближённый список частых значений и не хранит все различные названия.
SELECT
    category,
    topK(5)(title) AS popular_titles
FROM board.ads
GROUP BY category
ORDER BY category;

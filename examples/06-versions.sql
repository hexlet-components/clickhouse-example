-- История изменений и актуальное состояние. Таблица ad_versions хранит все
-- версии объявления, а снимок каталога ads показывает только последнюю.

-- История одного объявления. Продавец трижды снижал цену, и после
-- четвёртой версии объявление продано.
SELECT
    ad_id,
    version,
    changed_at,
    price,
    status
FROM board.ad_versions
WHERE ad_id = 42
ORDER BY version;

-- Актуальная версия через argMax. Функция берёт значение из строки с
-- наибольшим номером версии и работает на любом движке таблицы.
SELECT
    ad_id,
    max(version) AS last_version,
    argMax(price, version) AS price,
    argMax(status, version) AS status
FROM board.ad_versions
WHERE ad_id IN (1, 2, 3, 4, 5)
GROUP BY ad_id
ORDER BY ad_id;

-- Сверка со снимком каталога. Расхождений нет, потому что снимок собран из
-- тех же последних версий.
SELECT count() AS mismatches
FROM board.ads AS a
INNER JOIN
(
    SELECT
        ad_id,
        argMax(price, version) AS price
    FROM board.ad_versions
    GROUP BY ad_id
) AS v ON a.ad_id = v.ad_id
WHERE a.price != v.price;

-- ReplacingMergeTree оставляет одну строку на ключ, но только после слияния
-- частей. Копируем историю в отдельную базу и смотрим, что видит запрос до
-- слияния, с FINAL и после OPTIMIZE.
CREATE DATABASE IF NOT EXISTS board_lab;

DROP TABLE IF EXISTS board_lab.current_ads;

CREATE TABLE board_lab.current_ads
(
    ad_id UInt64,
    version UInt32,
    price UInt32,
    status Enum8('published' = 1, 'sold' = 2, 'archived' = 3)
)
ENGINE = ReplacingMergeTree(version)
ORDER BY ad_id;

-- Каждая версия вставляется отдельным запросом, поэтому старая и новая
-- строки одного объявления лежат в разных частях.
INSERT INTO board_lab.current_ads
SELECT ad_id, version, price, status
FROM board.ad_versions
WHERE version = 1;

INSERT INTO board_lab.current_ads
SELECT ad_id, version, price, status
FROM board.ad_versions
WHERE version > 1;

SELECT
    (SELECT count() FROM board_lab.current_ads) AS rows_before_merge,
    (SELECT count() FROM board_lab.current_ads FINAL) AS rows_with_final,
    (SELECT count() FROM board.ads) AS ads_in_catalog;

OPTIMIZE TABLE board_lab.current_ads FINAL;

SELECT count() AS rows_after_merge
FROM board_lab.current_ads;

DROP DATABASE board_lab;

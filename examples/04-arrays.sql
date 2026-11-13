-- Массивы. Фотографии и метки объявления хранятся в одной строке массивами,
-- а ARRAY JOIN разворачивает их в отдельные строки.

-- Сколько объявлений с каждой меткой. ARRAY JOIN превращает строку с тремя
-- метками в три строки, а объявления без меток из результата пропадают.
SELECT
    tag,
    count() AS ads
FROM board.ads
ARRAY JOIN tags AS tag
GROUP BY tag
ORDER BY ads DESC;

-- LEFT ARRAY JOIN оставляет объявления с пустым массивом. Для них tag
-- получает значение по умолчанию, то есть пустую строку.
SELECT
    tag = '' AS without_tags,
    count() AS rows
FROM board.ads
LEFT ARRAY JOIN tags AS tag
GROUP BY without_tags;

-- Число фотографий и продажи. Функции над массивами работают без
-- разворачивания, length считает элементы прямо в строке.
SELECT
    length(photos) AS photo_count,
    count() AS ads,
    round(countIf(status = 'sold') / ads * 100, 1) AS sold_percent
FROM board.ads
GROUP BY photo_count
ORDER BY photo_count;

-- Объявления с доставкой и торгом. has проверяет наличие элемента,
-- hasAll требует все перечисленные элементы сразу.
SELECT
    countIf(has(tags, 'доставка')) AS with_delivery,
    countIf(hasAll(tags, ['доставка', 'торг'])) AS with_delivery_and_bargain
FROM board.ads;

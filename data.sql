-- Наполнение учебной базы. Данные строятся из хешей номера строки, поэтому
-- при одном масштабе каждая загрузка даёт те же строки и те же ответы.
--
-- Масштаб передаётся параметром клиента --param_scale. При scale = 1
-- получаются 50 тысяч продавцов, 500 тысяч объявлений, 10 миллионов событий
-- и 50 тысяч входящих сообщений.

INSERT INTO board.sellers
SELECT
    toUInt32(number + 1) AS seller_id,
    concat(
        if(is_company, 'ООО «', ''),
        ['Алексей', 'Мария', 'Иван', 'Ольга', 'Дмитрий', 'Анна', 'Сергей', 'Елена', 'Павел', 'Наталья'][cityHash64(number, 'name') % 10 + 1],
        if(is_company, concat(' и партнёры', '»'), concat(' ', ['К.', 'С.', 'П.', 'М.', 'Л.', 'Н.'][cityHash64(number, 'surname') % 6 + 1]))
    ) AS name,
    [
        'Москва', 'Москва', 'Москва', 'Москва', 'Москва', 'Москва',
        'Санкт-Петербург', 'Санкт-Петербург', 'Санкт-Петербург', 'Санкт-Петербург',
        'Новосибирск', 'Екатеринбург', 'Казань', 'Нижний Новгород',
        'Краснодар', 'Самара', 'Пермь', 'Воронеж'
    ][cityHash64(seller_id, 'city') % 18 + 1] AS city,
    seller_id % 10 = 0 AS is_company,
    toDateTime('2022-01-01 00:00:00', 'Europe/Moscow') + toIntervalSecond(cityHash64(number, 'registered') % 136000000) AS registered_at
FROM numbers(toUInt64({scale:Float64} * 50000));

-- Версии объявлений. У объявления от одной до четырёх версий, каждая следующая
-- снижает цену на пять процентов. Статус последней версии решает, продано
-- объявление, снято или ещё висит. Объявление с фотографиями продаётся
-- чаще, без фотографий примерно каждое десятое, с шестью почти половина.
INSERT INTO board.ad_versions
SELECT
    ad_id,
    toUInt32(version) AS version,
    published_at + toIntervalSecond((version - 1) * (86400 + cityHash64(ad_id, version, 'gap') % 864000)) AS changed_at,
    toUInt32(intDiv(toUInt64(base_price * pow(0.95, version - 1)), 100) * 100) AS price,
    if(
        version < versions,
        'published',
        multiIf(final_roll < 10 + 6 * photo_count, 'sold', final_roll < 20 + 6 * photo_count, 'archived', 'published')
    ) AS status
FROM
(
    SELECT
        number + 1 AS ad_id,
        cityHash64(ad_id, 'category') % 10 AS category_roll,
        [1, 2, 3, 4, 5, 6, 7, 8, 8, 3][category_roll + 1] AS category_index,
        [150000, 1000, 300, 500, 2000, 5000, 200, 1000][category_index] AS min_price,
        [3000000, 60000, 15000, 80000, 120000, 400000, 30000, 200000][category_index] AS max_price,
        min_price + (max_price - min_price) * pow((cityHash64(ad_id, 'price') % 10000) / 10000, 2) AS base_price,
        1 + cityHash64(ad_id, 'versions') % 4 AS versions,
        cityHash64(ad_id, 'status') % 100 AS final_roll,
        cityHash64(ad_id, 'photos') % 7 AS photo_count,
        toDateTime('2026-01-01 00:00:00', 'Europe/Moscow') + toIntervalSecond(cityHash64(ad_id, 'published') % 18316800) AS published_at
    FROM numbers(toUInt64({scale:Float64} * 500000))
)
ARRAY JOIN range(1, versions + 1) AS version;

-- Снимок каталога собирается из последних версий, поэтому цена и статус в нём
-- совпадают с историей изменений.
INSERT INTO board.ads
SELECT
    ad_id,
    -- Компаниям принадлежит каждый десятый продавец и почти половина объявлений.
    toUInt32(if(
        cityHash64(ad_id, 'company') % 10 < 4,
        (cityHash64(ad_id, 'seller') % greatest(toUInt64({scale:Float64} * 5000), 1) + 1) * 10,
        cityHash64(ad_id, 'seller') % toUInt64({scale:Float64} * 50000) + 1
    )) AS seller_id,
    ['Авто', 'Мебель', 'Одежда', 'Спорт', 'Техника', 'Транспорт', 'Хобби', 'Электроника'][category_index] AS category,
    [
        'Москва', 'Москва', 'Москва', 'Москва', 'Москва', 'Москва',
        'Санкт-Петербург', 'Санкт-Петербург', 'Санкт-Петербург', 'Санкт-Петербург',
        'Новосибирск', 'Екатеринбург', 'Казань', 'Нижний Новгород',
        'Краснодар', 'Самара', 'Пермь', 'Воронеж'
    ][cityHash64(seller_id, 'city') % 18 + 1] AS city,
    [
        ['Lada Granta', 'Kia Rio', 'Hyundai Solaris', 'Toyota Camry', 'Volkswagen Polo', 'Skoda Octavia'],
        ['Диван угловой', 'Шкаф-купе', 'Стол обеденный', 'Кресло офисное', 'Комод', 'Кровать двуспальная'],
        ['Куртка зимняя', 'Платье вечернее', 'Кроссовки', 'Пальто шерстяное', 'Джинсы', 'Костюм деловой'],
        ['Велотренажёр', 'Гантели разборные', 'Лыжи беговые', 'Палатка туристическая', 'Скейтборд', 'Беговая дорожка'],
        ['Стиральная машина', 'Холодильник', 'Пылесос', 'Посудомоечная машина', 'Микроволновка', 'Кофемашина'],
        ['Велосипед горный', 'Электросамокат', 'Мотоцикл', 'Лодка надувная', 'Снегоход', 'Прицеп легковой'],
        ['Конструктор', 'Набор для рисования', 'Гитара акустическая', 'Коллекция марок', 'Настольная игра', 'Пазл на 1000 деталей'],
        ['Смартфон', 'Ноутбук', 'Наушники беспроводные', 'Телевизор', 'Планшет', 'Игровая приставка']
    ][category_index][cityHash64(ad_id, 'title') % 6 + 1] AS title,
    price,
    status,
    published_at,
    arrayMap(i -> concat('ads/', toString(ad_id), '/', toString(i), '.jpg'), range(1, toUInt64(cityHash64(ad_id, 'photos') % 7) + 1)) AS photos,
    arrayFilter(
        (tag, i) -> cityHash64(ad_id, i, 'tag') % 5 = 0,
        ['торг', 'доставка', 'срочно', 'обмен', 'новое', 'гарантия'],
        range(1, 7)
    ) AS tags
FROM
(
    SELECT
        ad_id,
        [1, 2, 3, 4, 5, 6, 7, 8, 8, 3][cityHash64(ad_id, 'category') % 10 + 1] AS category_index,
        argMax(price, version) AS price,
        argMax(status, version) AS status,
        min(changed_at) AS published_at
    FROM board.ad_versions
    GROUP BY ad_id
);

-- События за лето 2026 года. Популярные объявления получают большую часть
-- просмотров, вечером активность выше, чем ночью, а обращаются к продавцу
-- чаще всего в категории «Авто».
INSERT INTO board.events
SELECT
    e.event_id,
    if(
        e.raw_time >= a.published_at,
        e.raw_time,
        a.published_at + toIntervalSecond(cityHash64(e.event_id, 'shift') % greatest(toUInt64(toDateTime('2026-09-01 00:00:00', 'Europe/Moscow') - a.published_at), 1))
    ) AS event_time,
    multiIf(
        e.type_roll < if(a.category = 'Авто', 60, 25), 'contact',
        e.type_roll < if(a.category = 'Авто', 60, 25) + 60, 'favorite',
        'view'
    ) AS event_type,
    e.ad_id,
    e.visitor_id,
    a.category,
    a.city,
    e.device
FROM
(
    SELECT
        number + 1 AS event_id,
        toUInt64(pow((cityHash64(number, 'ad') % 1000000) / 1000000, 3) * {scale:Float64} * 500000) + 1 AS ad_id,
        toUInt64(pow((cityHash64(number, 'visitor') % 1000000) / 1000000, 2) * {scale:Float64} * 800000) + 1 AS visitor_id,
        toDateTime('2026-06-01 00:00:00', 'Europe/Moscow')
            + toIntervalDay(cityHash64(number, 'day') % 92)
            + toIntervalHour(hours[cityHash64(number, 'hour') % length(hours) + 1])
            + toIntervalSecond(cityHash64(number, 'second') % 3600) AS raw_time,
        -- Каждый час встречается хотя бы раз, днём и вечером чаще.
        arrayConcat(range(24), range(7, 24), [9, 10, 11, 12, 12, 13, 13, 14, 15, 16, 17, 18, 18, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21, 22, 22]) AS hours,
        cityHash64(number, 'type') % 1000 AS type_roll,
        ['mobile', 'mobile', 'mobile', 'desktop', 'desktop', 'app'][cityHash64(number, 'device') % 6 + 1] AS device
    FROM numbers(toUInt64({scale:Float64} * 10000000))
) AS e
INNER JOIN board.ads AS a ON e.ad_id = a.ad_id;

-- Входящие сообщения о новых объявлениях, которых ещё нет в каталоге.
-- У каждого двадцатого нет цены, каждое пятидесятое обрезано при передаче.
INSERT INTO board.incoming_ads
SELECT
    toDateTime('2026-09-01 00:00:00', 'Europe/Moscow') + toIntervalSecond(number * 17) AS received_at,
    if(
        cityHash64(number, 'broken') % 50 = 0,
        substring(document, 1, intDiv(length(document), 2)),
        document
    ) AS payload
FROM
(
    SELECT
        number,
        toUInt64({scale:Float64} * 500000) + number + 1 AS ad_id,
        cityHash64(number, 'category') % 8 + 1 AS category_index,
        2008 + cityHash64(number, 'year') % 18 AS car_year,
        ['Авто', 'Мебель', 'Одежда', 'Спорт', 'Техника', 'Транспорт', 'Хобби', 'Электроника'][category_index] AS category,
        [150000, 1000, 300, 500, 2000, 5000, 200, 1000][category_index] AS min_price,
        [3000000, 60000, 15000, 80000, 120000, 400000, 30000, 200000][category_index] AS max_price,
        toUInt32(cityHash64(number, 'seller') % toUInt64({scale:Float64} * 50000) + 1) AS seller_id,
        multiIf(
            category = 'Авто', concat(
                '{"brand":"', ['Lada', 'Kia', 'Hyundai', 'Toyota'][cityHash64(number, 'brand') % 4 + 1],
                '","year":', toString(car_year),
                ',"mileage_km":', toString((2026 - car_year) * (8000 + cityHash64(number, 'mileage') % 14000)), '}'
            ),
            category = 'Электроника', concat(
                '{"brand":"', ['Apple', 'Samsung', 'Xiaomi', 'Sony'][cityHash64(number, 'brand') % 4 + 1],
                '","condition":"', ['новое', 'как новое', 'б/у'][cityHash64(number, 'condition') % 3 + 1],
                '","warranty":', if(cityHash64(number, 'warranty') % 2 = 0, 'true', 'false'), '}'
            ),
            category = 'Одежда', concat(
                '{"size":"', ['XS', 'S', 'M', 'L', 'XL'][cityHash64(number, 'size') % 5 + 1],
                '","gender":"', ['женское', 'мужское', 'детское'][cityHash64(number, 'gender') % 3 + 1], '"}'
            ),
            category = 'Мебель', concat(
                '{"material":"', ['дерево', 'ЛДСП', 'металл'][cityHash64(number, 'material') % 3 + 1],
                '","width_cm":', toString(40 + cityHash64(number, 'width') % 200), '}'
            ),
            '{}'
        ) AS attributes,
        concat(
            '{"ad_id":', toString(ad_id),
            ',"category":"', category,
            '","seller":{"id":', toString(seller_id),
            ',"is_company":', if(cityHash64(number, 'company') % 10 = 0, 'true', 'false'), '},',
            if(cityHash64(number, 'no_price') % 20 = 0, '', concat('"price":', toString(intDiv(toUInt64(min_price + (max_price - min_price) * pow((cityHash64(number, 'price') % 10000) / 10000, 2)), 100) * 100), ',')),
            '"photos":[', arrayStringConcat(arrayMap(i -> concat('"ads/', toString(ad_id), '/', toString(i), '.jpg"'), range(1, toUInt64(cityHash64(number, 'photos') % 5) + 1)), ','), ']',
            ',"attributes":', attributes, '}'
        ) AS document
    FROM numbers(toUInt64({scale:Float64} * 50000))
);

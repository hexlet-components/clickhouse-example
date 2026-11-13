-- Схема учебной базы доски объявлений.
-- Повторная загрузка пересоздаёт базу board целиком.

DROP DATABASE IF EXISTS board;

CREATE DATABASE board;

-- Продавцы. Частные лица и компании из десяти городов.
CREATE TABLE board.sellers
(
    seller_id UInt32,
    name String,
    city LowCardinality(String),
    is_company Bool,
    registered_at DateTime('Europe/Moscow')
)
ENGINE = MergeTree
ORDER BY seller_id;

-- История изменений объявления. Каждая правка цены или статуса добавляет
-- строку со следующим номером версии, старые строки остаются.
CREATE TABLE board.ad_versions
(
    ad_id UInt64,
    version UInt32,
    changed_at DateTime('Europe/Moscow'),
    price UInt32,
    status Enum8('published' = 1, 'sold' = 2, 'archived' = 3)
)
ENGINE = MergeTree
ORDER BY (ad_id, version);

-- Снимок каталога. Одна строка на объявление с последней ценой и статусом.
CREATE TABLE board.ads
(
    ad_id UInt64,
    seller_id UInt32,
    category LowCardinality(String),
    city LowCardinality(String),
    title String,
    price UInt32,
    status Enum8('published' = 1, 'sold' = 2, 'archived' = 3),
    published_at DateTime('Europe/Moscow'),
    photos Array(String),
    tags Array(LowCardinality(String))
)
ENGINE = MergeTree
ORDER BY (category, city, ad_id);

-- Просмотры, добавления в избранное и обращения к продавцу.
CREATE TABLE board.events
(
    event_id UInt64,
    event_time DateTime('Europe/Moscow'),
    event_type Enum8('view' = 1, 'favorite' = 2, 'contact' = 3),
    ad_id UInt64,
    visitor_id UInt64,
    category LowCardinality(String),
    city LowCardinality(String),
    device LowCardinality(String)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_time)
ORDER BY (event_type, category, event_time);

-- Входящие сообщения о публикации объявлений в виде JSON-текста.
-- Часть сообщений неполная, их отбраковывают при разборе.
CREATE TABLE board.incoming_ads
(
    received_at DateTime('Europe/Moscow'),
    payload String
)
ENGINE = MergeTree
ORDER BY received_at;

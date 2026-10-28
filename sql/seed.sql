-- Тестовые данные. «Сейчас» в запросах — 27.10.2026 12:00.

INSERT INTO brand (id, name) VALUES
    ('FEBI',   'FEBI BILSTEIN'),
    ('ASAM',   'ASAM'),
    ('GLASER', 'GLASER'),
    ('AP',     'AP'),
    ('OSSCA',  'OSSCA');

INSERT INTO warehouse (id, name, own) VALUES
    ('MSK-1', 'Москва, основной склад', true),
    ('BRN-1', 'Брянск',                 true),
    ('SUP-A', 'Склад поставщика «Автодеталь»', false),
    ('SUP-B', 'Склад поставщика «Партс»',      false);

INSERT INTO product (id, article, article_normalized, brand_id, name, active, updated_at) VALUES
    ('P1', '01-089',    '01089',    'FEBI',   'Антифриз G11, 1,5 л',          true,  '2026-10-27 10:12:41'),
    ('P2', '01089',     '01089',    'ASAM',   'Фильтр топливный',             true,  '2026-10-27 09:40:00'),
    ('P3', 'H01089-00', 'H0108900', 'GLASER', 'Прокладка ГБЦ',                true,  '2026-10-26 18:05:00'),
    ('P4', '01.089',    '01089',    'AP',     'Колодки тормозные барабанные', true,  '2026-10-25 11:00:00'),
    ('P5', '01089',     '01089',    'OSSCA',  'Стеклоподъёмник задний левый', true,  '2026-10-27 08:15:00'),
    ('P6', '22-404',    '22404',    'FEBI',   'Ремень приводной',             false, '2026-09-30 12:00:00'),
    ('P7', '33/101',    '33101',    'AP',     'Диск тормозной',               true,  '2026-10-20 10:00:00');

INSERT INTO stock (product_id, warehouse_id, quantity, price, shipment_date, updated_at) VALUES
    ('P1', 'MSK-1', 120, 1082.00, '2026-10-29', '2026-10-27 10:13:00'),
    ('P1', 'BRN-1',   8, 1082.00, '2026-10-28', '2026-10-27 10:13:00'),
    ('P1', 'SUP-A',  50, 1314.00, '2026-10-30', '2026-10-27 06:00:00'),
    ('P2', 'MSK-1',  28,   86.88, '2026-10-28', '2026-10-27 09:41:00'),
    ('P2', 'SUP-B',  10,   79.90, '2026-10-31', '2026-10-24 06:00:00'),
    ('P3', 'SUP-A',   7, 1184.38, '2026-10-30', '2026-10-27 06:00:00'),
    ('P3', 'SUP-B',   7, 1251.60, '2026-10-31', '2026-10-24 06:00:00'),
    ('P4', 'MSK-1',   0, 1505.80, NULL,         '2026-10-25 11:00:00'),
    ('P5', 'MSK-1',  20, 1067.26, '2026-10-29', '2026-10-27 08:16:00'),
    ('P6', 'MSK-1',   3,  540.00, '2026-10-28', '2026-09-30 12:00:00');

INSERT INTO supplier (id, name, warehouse_id, last_loaded_at) VALUES
    ('S-A', 'Автодеталь', 'SUP-A', '2026-10-27 06:00:00'),
    ('S-B', 'Партс',      'SUP-B', '2026-10-24 06:00:00');

INSERT INTO supplier_match (supplier_id, supplier_article, supplier_brand, product_id, status, decided_by) VALUES
    ('S-A', '01-089',    'FEBI',          'P1', 'auto',      NULL),
    ('S-A', 'H01089-00', 'Glaser',        'P3', 'auto',      NULL),
    ('S-A', '01089',     'NGK/NTK',       NULL, 'not_found', NULL),
    ('S-A', '01 089',    'FEBI BILSTEIN', NULL, 'ambiguous', NULL),
    ('S-B', '01089',     'ASAM',          'P2', 'manual',    'Иванова А.'),
    ('S-B', 'H0108900',  'GLASER',        'P3', 'auto',      NULL),
    ('S-B', '33-101',    'A.P.',          NULL, 'ambiguous', NULL),
    ('S-B', '77-001',    'MEYLE',         NULL, 'not_found', NULL);

INSERT INTO exchange_package (id, source, type, received_at, accepted, rejected) VALUES
    ('PK-101', '1c',       'delta',      '2026-10-27 09:00:00', 1000,   0),
    ('PK-102', '1c',       'delta',      '2026-10-27 09:05:00',  998,   2),
    ('PK-103', '1c',       'delta',      '2026-10-27 09:10:00',  640,   0),
    ('PK-104', '1c',       'full',       '2026-10-27 03:00:00',  995,   5),
    ('PK-105', 'supplier', 'price_list', '2026-10-27 06:00:00', 4210,  37),
    ('PK-099', '1c',       'delta',      '2026-10-26 17:55:00', 1000,   0);

INSERT INTO package_error (package_id, product_id, code, message) VALUES
    ('PK-102', 'P4',  'INVALID_PRICE',     'Цена должна быть больше 0'),
    ('PK-102', 'P7',  'UNKNOWN_WAREHOUSE', 'Склада SPB-9 нет в справочнике сайта'),
    ('PK-104', 'P4',  'INVALID_PRICE',     'Цена должна быть больше 0'),
    ('PK-104', 'P7',  'UNKNOWN_WAREHOUSE', 'Склада SPB-9 нет в справочнике сайта'),
    ('PK-104', 'X1',  'UNKNOWN_BRAND',     'Производителя BOSCHH нет в справочнике сайта'),
    ('PK-104', 'X2',  'UNKNOWN_WAREHOUSE', 'Склада SPB-9 нет в справочнике сайта'),
    ('PK-104', 'X3',  'REQUIRED_FIELD',    'Не заполнено поле name');

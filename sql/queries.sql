-- Запросы к модели данных из ТЗ. Каждый отвечает на вопрос бизнеса или поддержки.
-- «Сейчас» — 27.10.2026 12:00, в запросах эта дата задана явно, чтобы результат был воспроизводимым.

-- 1. Что покупатель видит в каталоге: цена «от» и общий остаток по каждому активному товару.
--    Склады с нулевым остатком в цене не участвуют (как в ТЗ, ФТ про цену со складов).
SELECT
    p.article,
    p.brand_id,
    p.name,
    MIN(CASE WHEN s.quantity > 0 THEN s.price END) AS price_from,
    COALESCE(SUM(s.quantity), 0)                  AS total_quantity
FROM product p
LEFT JOIN stock s ON s.product_id = p.id
WHERE p.active = true
GROUP BY p.id, p.article, p.brand_id, p.name
ORDER BY total_quantity DESC, p.article;

-- 2. Активные товары, которых нет в наличии ни на одном складе.
--    Сюда попадает и товар без единой строки в stock, поэтому NOT EXISTS, а не JOIN.
SELECT p.article, p.brand_id, p.name
FROM product p
WHERE p.active = true
  AND NOT EXISTS (
      SELECT 1
      FROM stock s
      WHERE s.product_id = p.id
        AND s.quantity > 0
  )
ORDER BY p.article;

-- 3. Самый дешёвый склад для каждого товара в наличии.
--    Оконная функция нумерует склады товара по цене, берём первый.
SELECT article, brand_id, warehouse_id, price, quantity
FROM (
    SELECT
        p.article,
        p.brand_id,
        s.warehouse_id,
        s.price,
        s.quantity,
        ROW_NUMBER() OVER (PARTITION BY s.product_id ORDER BY s.price, s.shipment_date) AS rn
    FROM stock s
    JOIN product p ON p.id = s.product_id
    WHERE s.quantity > 0
      AND p.active = true
) ranked
WHERE rn = 1
ORDER BY article, brand_id;

-- 4. Товары, у которых цена на разных складах отличается больше чем на 10%.
--    Повод проверить наценку или ошибку в прайсе поставщика.
SELECT
    p.article,
    p.brand_id,
    MIN(s.price)                                        AS min_price,
    MAX(s.price)                                        AS max_price,
    ROUND((MAX(s.price) - MIN(s.price)) * 100.0 / MIN(s.price), 1) AS spread_pct
FROM stock s
JOIN product p ON p.id = s.product_id
GROUP BY p.id, p.article, p.brand_id
HAVING (MAX(s.price) - MIN(s.price)) * 100.0 / MIN(s.price) > 10
ORDER BY spread_pct DESC;

-- 5. Один нормализованный артикул у разных производителей.
--    Это главный риск сопоставления из ТЗ: такие позиции нельзя сопоставлять по артикулу без бренда.
SELECT
    article_normalized,
    COUNT(*)                            AS products,
    COUNT(DISTINCT brand_id)            AS brands
FROM product
GROUP BY article_normalized
HAVING COUNT(DISTINCT brand_id) > 1
ORDER BY brands DESC;

-- 6. Поставщики, чей прайс не обновлялся больше 24 часов.
--    По ТЗ их остатки должны быть скрыты с сайта. Запрос показывает, сколько строк остатков под угрозой.
SELECT
    sp.name                      AS supplier,
    sp.last_loaded_at,
    COUNT(s.product_id)          AS stock_rows,
    COALESCE(SUM(s.quantity), 0) AS quantity
FROM supplier sp
LEFT JOIN stock s ON s.warehouse_id = sp.warehouse_id
WHERE sp.last_loaded_at IS NULL
   OR sp.last_loaded_at < '2026-10-26 12:00:00'
GROUP BY sp.id, sp.name, sp.last_loaded_at;

-- 7. Очередь ручной проверки по поставщикам: сколько позиций ждёт контент-менеджера.
SELECT
    sp.name                                                   AS supplier,
    SUM(CASE WHEN m.status = 'not_found' THEN 1 ELSE 0 END)   AS not_found,
    SUM(CASE WHEN m.status = 'ambiguous' THEN 1 ELSE 0 END)   AS ambiguous,
    SUM(CASE WHEN m.status IN ('auto', 'manual') THEN 1 ELSE 0 END) AS matched
FROM supplier sp
JOIN supplier_match m ON m.supplier_id = sp.id
GROUP BY sp.id, sp.name
ORDER BY not_found + ambiguous DESC;

-- 8. Журнал обмена за сутки: пакеты с ошибками и доля отклонённых позиций.
SELECT
    id,
    source,
    type,
    received_at,
    accepted,
    rejected,
    ROUND(rejected * 100.0 / (accepted + rejected), 2) AS rejected_pct
FROM exchange_package
WHERE received_at >= '2026-10-27 00:00:00'
  AND received_at <  '2026-10-28 00:00:00'
  AND rejected > 0
ORDER BY rejected_pct DESC;

-- 9. Самые частые ошибки обмена с 1С за сутки — что чинить в первую очередь.
SELECT
    e.code,
    COUNT(*)                     AS errors,
    COUNT(DISTINCT e.product_id) AS products
FROM package_error e
JOIN exchange_package pk ON pk.id = e.package_id
WHERE pk.source = '1c'
  AND pk.received_at >= '2026-10-27 00:00:00'
  AND pk.received_at <  '2026-10-28 00:00:00'
GROUP BY e.code
ORDER BY errors DESC, e.code;

-- 10. Товары, которые повторяют одну и ту же ошибку в нескольких пакетах.
--     Если ошибка не исчезает, её нужно исправить в 1С, а не ждать следующего обмена.
SELECT
    e.product_id,
    e.code,
    COUNT(DISTINCT e.package_id) AS packages,
    MAX(pk.received_at)          AS last_seen
FROM package_error e
JOIN exchange_package pk ON pk.id = e.package_id
GROUP BY e.product_id, e.code
HAVING COUNT(DISTINCT e.package_id) > 1
ORDER BY packages DESC, e.product_id;

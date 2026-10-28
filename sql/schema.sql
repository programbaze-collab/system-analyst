-- Модель данных из ТЗ «Обмен товарами, ценами и остатками между интернет-магазином и 1С» (раздел 6),
-- дополненная справочниками и журналом обмена.
-- Синтаксис стандартный: работает в PostgreSQL и SQLite.

CREATE TABLE brand (
    id   VARCHAR(50)  PRIMARY KEY,          -- код производителя, например FEBI
    name VARCHAR(100) NOT NULL
);

CREATE TABLE warehouse (
    id   VARCHAR(20)  PRIMARY KEY,          -- код склада, например MSK-1
    name VARCHAR(100) NOT NULL,
    own  BOOLEAN      NOT NULL              -- true — свой склад, false — склад поставщика
);

CREATE TABLE product (
    id                 VARCHAR(36)  PRIMARY KEY,   -- код товара в 1С (GUID)
    article            VARCHAR(50)  NOT NULL,      -- артикул, как в 1С
    article_normalized VARCHAR(50)  NOT NULL,      -- без пробелов, дефисов, точек и слэшей, заглавными
    brand_id           VARCHAR(50)  NOT NULL REFERENCES brand (id),
    name               VARCHAR(255) NOT NULL,
    active             BOOLEAN      NOT NULL,      -- false — снят с продажи
    updated_at         TIMESTAMP    NOT NULL       -- когда товар менялся в 1С
);

CREATE TABLE stock (
    product_id    VARCHAR(36)   NOT NULL REFERENCES product (id),
    warehouse_id  VARCHAR(20)   NOT NULL REFERENCES warehouse (id),
    quantity      INTEGER       NOT NULL CHECK (quantity >= 0),
    price         NUMERIC(12,2) NOT NULL CHECK (price > 0),   -- ₽ с НДС
    shipment_date DATE,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (product_id, warehouse_id)
);

CREATE TABLE supplier (
    id             VARCHAR(20)  PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    warehouse_id   VARCHAR(20)  NOT NULL REFERENCES warehouse (id),  -- куда пишутся остатки из прайса
    last_loaded_at TIMESTAMP                                         -- последняя успешная загрузка прайса
);

CREATE TABLE supplier_match (
    supplier_id      VARCHAR(20) NOT NULL REFERENCES supplier (id),
    supplier_article VARCHAR(50) NOT NULL,
    supplier_brand   VARCHAR(50) NOT NULL,
    product_id       VARCHAR(36) REFERENCES product (id),            -- пусто, пока не сопоставлено
    status           VARCHAR(20) NOT NULL
                     CHECK (status IN ('auto', 'manual', 'not_found', 'ambiguous')),
    decided_by       VARCHAR(100),
    PRIMARY KEY (supplier_id, supplier_article, supplier_brand)
);

CREATE TABLE exchange_package (
    id          VARCHAR(36) PRIMARY KEY,
    source      VARCHAR(20) NOT NULL CHECK (source IN ('1c', 'supplier')),
    type        VARCHAR(20) NOT NULL CHECK (type IN ('delta', 'full', 'price_list')),
    received_at TIMESTAMP   NOT NULL,
    accepted    INTEGER     NOT NULL,
    rejected    INTEGER     NOT NULL
);

CREATE TABLE package_error (
    package_id VARCHAR(36)  NOT NULL REFERENCES exchange_package (id),
    product_id VARCHAR(36)  NOT NULL,
    code       VARCHAR(30)  NOT NULL,
    message    VARCHAR(255) NOT NULL
);

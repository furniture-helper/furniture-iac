CREATE TABLE IF NOT EXISTS page_labels_with_llm
(
    url           TEXT        NOT NULL,
    content       TEXT        NOT NULL,
    type          VARCHAR(50) NOT NULL,
    product_title VARCHAR(255),
    product_image TEXT,
    product_price DECIMAL(10, 2),
    brand         VARCHAR(255),
    in_stock      BOOLEAN,
    attributes    JSONB,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (url)
);
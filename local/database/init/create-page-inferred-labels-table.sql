CREATE TABLE IF NOT EXISTS page_inferred_labels
(
    url              TEXT NOT NULL,
    product_title    VARCHAR(255),
    product_price    DECIMAL(10, 2),
    last_inferred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (url)
);

-- Change product title to VARCHAR(511) to accommodate longer titles
ALTER TABLE page_inferred_labels
    ALTER COLUMN product_title TYPE VARCHAR;

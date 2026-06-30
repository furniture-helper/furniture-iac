CREATE TABLE product_search_documents
(
    url             text PRIMARY KEY,
    product_title   varchar,
    text            text,

    search_vector   tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(product_title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(text, '')), 'B')
        ) STORED,

    created_at      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX product_search_gin_idx
    ON product_search_documents USING GIN (search_vector);

-- 1. Drop the existing generated column
ALTER TABLE product_search_documents
    DROP COLUMN search_vector;

-- 2. Add the column back with the flipped weights
-- 'A' is now assigned to the 'text' field
-- 'B' is now assigned to the 'product_title' field
ALTER TABLE product_search_documents
    ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(text, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(product_title, '')), 'A')
        ) STORED;

-- 3. Rebuild the index (Crucial for performance)
-- If you had an index on the old column, you must recreate it for the new one
CREATE INDEX idx_search_vector ON product_search_documents USING GIN (search_vector);

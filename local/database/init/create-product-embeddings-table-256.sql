CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS products_embeddings_256
(
    url             TEXT        NOT NULL,
    embedding       vector(256),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (url)
);

CREATE INDEX ON products_embeddings_256 USING hnsw (embedding vector_cosine_ops);

SELECT s3_key
FROM page_inferred_labels
         INNER JOIN pages ON page_inferred_labels.url = pages.url
WHERE page_inferred_labels.product_title = 'Parker Conference Table - NCF 006';
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS products_embeddings_1024
(
    url             TEXT        NOT NULL,
    embedding       vector(1024),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (url)
);

CREATE INDEX ON products_embeddings_1024 USING hnsw (embedding vector_cosine_ops);
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS products_embeddings_finetuned_768
(
    url             TEXT        NOT NULL,
    embedding       vector(768),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (url)
);

CREATE INDEX ON products_embeddings_finetuned_768 USING hnsw (embedding vector_cosine_ops);
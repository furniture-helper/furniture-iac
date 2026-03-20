CREATE TABLE IF NOT EXISTS minimized_pages
(
    url               TEXT PRIMARY KEY,
    s3_key            TEXT NOT NULL,
    last_minimized_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (url) REFERENCES pages (url) ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION minimized_pages_update_updated_at()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_minimized_pages_updated_at
    BEFORE UPDATE
    ON minimized_pages
    FOR EACH ROW
EXECUTE FUNCTION minimized_pages_update_updated_at();
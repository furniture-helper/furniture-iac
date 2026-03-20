CREATE TABLE IF NOT EXISTS crawl_logs
(
    log_id     SERIAL PRIMARY KEY,
    url        TEXT                     NOT NULL,
    domain     VARCHAR(100)             NOT NULL,
    crawled_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_crawl_logs_domain ON crawl_logs (domain);
CREATE INDEX IF NOT EXISTS idx_crawl_logs_url ON crawl_logs (url);
CREATE INDEX IF NOT EXISTS idx_crawl_logs_crawled_at ON crawl_logs (crawled_at);

CREATE OR REPLACE FUNCTION log_crawl_event()
    RETURNS TRIGGER AS
$$
BEGIN
    IF (TG_OP = 'INSERT') OR (OLD.last_crawled_at IS DISTINCT FROM NEW.last_crawled_at) THEN
        INSERT INTO crawl_logs (url, domain, crawled_at)
        VALUES (NEW.url, NEW.domain, NEW.last_crawled_at);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_crawls
    AFTER INSERT OR UPDATE
    ON pages
    FOR EACH ROW
    WHEN (
        NEW.last_crawled_at IS NOT NULL
            AND NEW.last_crawled_at > '1970-01-01 00:00:00+00'
        )
EXECUTE FUNCTION log_crawl_event();
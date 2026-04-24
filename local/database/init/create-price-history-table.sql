CREATE TABLE IF NOT EXISTS product_price_history (
    url         TEXT NOT NULL,
    price       NUMERIC(10, 2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (url, recorded_at)
);

CREATE INDEX IF NOT EXISTS idx_product_price_history_url
    ON product_price_history (url);

ALTER TABLE IF EXISTS product_price_history
    ALTER COLUMN price DROP NOT NULL;

CREATE OR REPLACE FUNCTION record_price_change()
RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO product_price_history (url, price, recorded_at)
    VALUES (NEW.url, NEW.product_price, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_record_price_changes ON page_inferred_labels;

CREATE TRIGGER trg_record_price_changes
    AFTER INSERT OR UPDATE ON page_inferred_labels
    FOR EACH ROW
    EXECUTE FUNCTION record_price_change();

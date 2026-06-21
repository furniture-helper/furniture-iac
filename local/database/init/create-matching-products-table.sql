CREATE TABLE IF NOT EXISTS matching_products
(
    url_1    TEXT    NOT NULL,
    url_2    TEXT    NOT NULL,
    matching BOOLEAN NOT NULL,
    PRIMARY KEY (url_1, url_2)
);

CREATE TABLE IF NOT EXISTS page_classifications
(
    url                TEXT        NOT NULL,
    s3_key             TEXT        NOT NULL,
    type               VARCHAR(50) NOT NULL,
    last_classified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (url)
);
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA analytics;
CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE analytics.success_crawler_events
(
    id       BIGSERIAL   NOT NULL,
    event_ts TIMESTAMPTZ NOT NULL,
    url      TEXT        NOT NULL,
    domain   TEXT        NOT NULL,
    host     TEXT        NOT NULL,
    region   TEXT        NOT NULL,
    duration INTERVAL    NOT NULL,
    PRIMARY KEY (id, event_ts)
) PARTITION BY RANGE (event_ts);

SELECT analytics.create_parent(
               p_parent_table => 'analytics.success_crawler_events',
               p_control => 'event_ts',
               p_interval => '1 day',
               p_premake => 3
       );

UPDATE analytics.part_config
SET retention            = '90 days',
    retention_keep_table = false
WHERE parent_table = 'analytics.success_crawler_events';

CREATE TABLE analytics.failed_crawler_events
(
    id            BIGSERIAL   NOT NULL,
    event_ts      TIMESTAMPTZ NOT NULL,
    url           TEXT        NOT NULL,
    domain        TEXT        NOT NULL,
    host          TEXT        NOT NULL,
    region        TEXT        NOT NULL,
    error_message TEXT        NOT NULL,
    PRIMARY KEY (id, event_ts)
) PARTITION BY RANGE (event_ts);

SELECT analytics.create_parent(
               p_parent_table => 'analytics.failed_crawler_events',
               p_control => 'event_ts',
               p_interval => '1 day',
               p_premake => 3
       );

UPDATE analytics.part_config
SET retention            = '90 days',
    retention_keep_table = false
WHERE parent_table = 'analytics.failed_crawler_events';

CREATE TABLE analytics.minimizer_events
(
    id             BIGSERIAL   NOT NULL,
    event_ts       TIMESTAMPTZ NOT NULL,
    url            TEXT        NOT NULL,
    domain         TEXT        NOT NULL,
    original_size  BIGINT      NOT NULL,
    minimized_size BIGINT      NOT NULL,
    PRIMARY KEY (id, event_ts)
) PARTITION BY RANGE (event_ts);

SELECT analytics.create_parent(
               p_parent_table => 'analytics.minimizer_events',
               p_control => 'event_ts',
               p_interval => '1 day',
               p_premake => 3
       );

UPDATE analytics.part_config
SET retention            = '90 days',
    retention_keep_table = false
WHERE parent_table = 'analytics.success_minimizer_events';

SELECT cron.schedule('@daily', $$SELECT analytics.run_maintenance_proc();$$);

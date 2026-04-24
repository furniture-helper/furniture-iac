CREATE USER datastream_user WITH LOGIN PASSWORD '<password>';


GRANT rds_replication TO datastream_user;

CREATE PUBLICATION pages_publication FOR TABLE public.pages;
SELECT pg_create_logical_replication_slot('pages_replication_slot', 'pgoutput');

CREATE PUBLICATION minimized_pages_publication FOR TABLE public.minimized_pages;
SELECT pg_create_logical_replication_slot('minimized_pages_replication_slot', 'pgoutput');

CREATE PUBLICATION classified_pages_publication FOR TABLE public.page_classifications;
SELECT pg_create_logical_replication_slot('page_classifications_replication_slot', 'pgoutput');

CREATE PUBLICATION inferred_pages_publication FOR TABLE public.page_inferred_labels;
SELECT pg_create_logical_replication_slot('page_inferences_replication_slot', 'pgoutput');

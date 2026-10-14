CREATE USER terraform_user LOGIN;

GRANT rds_iam TO terraform_user;
GRANT CONNECT ON DATABASE furniture TO terraform_user;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM terraform_user;
REVOKE ALL ON ALL TABLES IN SCHEMA analytics FROM terraform_user;

GRANT USAGE ON SCHEMA public TO terraform_user;
GRANT USAGE ON SCHEMA analytics TO terraform_user;
GRANT CREATE ON SCHEMA public TO terraform_user;
GRANT CREATE ON SCHEMA analytics TO terraform_user;
ALTER ROLE terraform_user CREATEROLE;

GRANT rds_iam TO terraform_user WITH ADMIN OPTION;
GRANT furniture TO terraform_user;


GRANT CONNECT ON DATABASE metabase TO terraform_user;
GRANT USAGE ON SCHEMA public TO terraform_user;

SELECT pg_rules.tablename, pg_rules.schemaname, pg_rules.ruleowner, pg_rules.rulename, pg_rules.definition
FROM pg_rules
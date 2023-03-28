
-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE PROCEDURE getRows(from_table string, count int)
  returns array
  language python
  runtime_version = '3.8'
  packages = ('snowflake-snowpark-python')
  handler = 'run'
AS
$$
def run(session, from_table, count):
  return session.table(from_table).limit(count).collect()
$$;

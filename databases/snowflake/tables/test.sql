
-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE TABLE TEST
(
    ID NUMBER
    ,NOTES VARCHAR
);

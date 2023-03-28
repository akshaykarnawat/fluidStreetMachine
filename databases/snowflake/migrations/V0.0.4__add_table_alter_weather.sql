-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE TABLE TEST
(
     ID number
    , NOTES VARCHAR
    ,T TIMESTAMP
);

ALTER TABLE WEATHER DROP COLUMN V;

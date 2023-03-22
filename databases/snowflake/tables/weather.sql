
-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE TABLE WEATHER
(
     V VARIANT
    ,T TIMESTAMP
);

-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE STAGE WEATHER
    URL = 's3://snowflake-workshop-lab/weather-nyc';

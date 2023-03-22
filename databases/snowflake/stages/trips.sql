
-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

CREATE OR REPLACE STAGE TRIPS
    URL = 's3://snowflake-workshop-lab/citibike-trips';
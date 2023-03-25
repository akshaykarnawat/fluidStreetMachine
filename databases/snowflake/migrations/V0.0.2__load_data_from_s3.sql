-- -- Set the database and schema context
-- USE SCHEMA {{ DB }}.{{ SCHEMA }};

-- -- Load the trips data -- ** CAUTION ** 1G+ dataset size
-- COPY INTO TRIPS FROM @TRIPS
--     FILE_FORMAT = (FORMAT_NAME = 'CSV_NO_HEADER')
--     PATTERN='.*.csv.gz';

-- -- Load the weather data
-- COPY INTO WEATHER FROM
--     (
--         SELECT
--              $1
--             ,CONVERT_TIMEZONE('UTC', 'US/Eastern', $1:time::TIMESTAMP_NTZ)
--         FROM @WEATHER
--     )
--     FILE_FORMAT = (FORMAT_NAME = 'JSON');

SELECT 1;

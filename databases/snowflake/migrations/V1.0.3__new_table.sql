
-- Set the database and schema context
USE SCHEMA {{ DB }}.{{ SCHEMA }};

-- create a new test table
CREATE OR REPLACE TABLE TEST_NEW
(
     ID NUMBER
    ,NOTES VARCHAR
);

-- insert some values into the table
INSERT INTO TEST_NEW(ID, NOTES)
VALUES
(1, 'This is the first row')
,(2, 'This is the second row');


ALTER TABLE TEST DROP COLUMN NOTES;
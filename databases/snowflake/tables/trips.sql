
CREATE OR REPLACE TABLE TRIPS
(
     TRIPDURATION INTEGER
    ,STARTTIME TIMESTAMP
    ,STOPTIME TIMESTAMP
    ,START_STATION_ID INTEGER
    ,START_STATION_NAME STRING
    ,START_STATION_LATITUDE FLOAT
    ,START_STATION_LONGITUDE FLOAT
    ,END_STATION_ID INTEGER
    ,END_STATION_NAME STRING
    ,END_STATION_LATITUDE FLOAT
    ,END_STATION_LONGITUDE FLOAT
    ,BIKEID INTEGER
    ,MEMBERSHIP_TYPE STRING
    ,USERTYPE STRING
    ,BIRTH_YEAR INTEGER
    ,GENDER INTEGER
);
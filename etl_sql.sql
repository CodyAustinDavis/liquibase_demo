--- Simulate ETLing data into existing production env
USE CATALOG main;
USE SCHEMA iot_dashboard_prod_lb;


COPY INTO bronze_sensors
FROM (SELECT 
      id::bigint AS Id,
      device_id::integer AS device_id,
      user_id::integer AS user_id,
      calories_burnt::decimal(10,2) AS calories_burnt, 
      miles_walked::decimal(10,2) AS miles_walked, 
      num_steps::decimal(10,2) AS num_steps, 
      timestamp::timestamp AS timestamp,
      value  AS value -- This is a JSON object
FROM "/databricks-datasets/iot-stream/data-device/")
FILEFORMAT = json -- csv, xml, txt, parquet, binary, etc.
COPY_OPTIONS('force'='false') --'true' always loads all data it sees. option to be incremental or always load all files
;

--Other Helpful copy options:
/*
PATTERN('[A-Za-z0-9].json')
FORMAT_OPTIONS ('ignoreCorruptFiles' = 'true') -- skips bad files for more robust incremental loads
COPY_OPTIONS ('mergeSchema' = 'true')
'ignoreChanges' = 'true' - ENSURE DOWNSTREAM PIPELINE CAN HANDLE DUPLICATE ALREADY PROCESSED RECORDS WITH MERGE/INSERT WHERE NOT EXISTS/Etc.
'ignoreDeletes' = 'true'
*/


MERGE INTO silver_sensors AS target
USING (
WITH de_dup (
SELECT Id::integer,
              device_id::integer,
              user_id::integer,
              calories_burnt::decimal,
              miles_walked::decimal,
              num_steps::decimal,
              timestamp::timestamp,
              value::string,
              ROW_NUMBER() OVER(PARTITION BY device_id, user_id, timestamp ORDER BY timestamp DESC) AS DupRank
              FROM bronze_sensors
              )
              
SELECT Id, device_id, user_id, calories_burnt, miles_walked, num_steps, timestamp, value
FROM de_dup
WHERE DupRank = 1
) AS source
ON source.Id = target.Id
AND source.user_id = target.user_id
AND source.device_id = target.device_id
WHEN MATCHED THEN UPDATE SET 
  target.calories_burnt = source.calories_burnt,
  target.miles_walked = source.miles_walked,
  target.num_steps = source.num_steps,
  target.timestamp = source.timestamp
WHEN NOT MATCHED THEN INSERT (calories_burnt, miles_walked, num_steps, timestamp)
VALUES (source.calories_burnt, source.miles_walked, source.num_steps, source.timestamp);


ANALYZE TABLE silver_sensors COMPUTE STATISTICS FOR ALL COLUMNS;

OPTIMIZE silver_sensors;


-- Truncate bronze batch once successfully loaded
-- This is the classical batch design pattern - but we can also now use streaming tables
TRUNCATE TABLE bronze_sensors;

-----===== END OF SENSOR PIPELINE ====----


-----===== START OF USERS PIPELINE =====-----

-- Incrementally Ingest Raw User Data
COPY INTO bronze_users
FROM (SELECT 
      userid::bigint AS userid,
      gender AS gender,
      age::integer AS age,
      height::decimal(10,2) AS height, 
      weight::decimal(10,2) AS weight,
      smoker AS smoker,
      familyhistory AS familyhistory,
      cholestlevs AS cholestlevs,
      bp AS bp,
      risk::decimal(10,2) AS risk,
      current_timestamp() AS update_timestamp
FROM "/databricks-datasets/iot-stream/data-user/")
FILEFORMAT = CSV
FORMAT_OPTIONS('header'='true')
COPY_OPTIONS('force'='false') --option to be incremental or always load all files
;

-- UPSERT Users

MERGE INTO silver_users AS target
USING (SELECT 
      userid::int,
      gender::string,
      age::int,
      height::decimal, 
      weight::decimal,
      smoker,
      familyhistory,
      cholestlevs,
      bp,
      risk,
      update_timestamp
      FROM bronze_users) AS source
ON source.userid = target.userid
WHEN MATCHED THEN UPDATE SET 
  target.gender = source.gender,
      target.age = source.age,
      target.height = source.height, 
      target.weight = source.weight,
      target.smoker = source.smoker,
      target.familyhistory = source.familyhistory,
      target.cholestlevs = source.cholestlevs,
      target.bp = source.bp,
      target.risk = source.risk,
      target.update_timestamp = source.update_timestamp
WHEN NOT MATCHED THEN INSERT (gender, age, height, weight, smoker, familyhistory, cholestlevs, bp, risk, update_timestamp)
      VALUES (source.gender, source.age, source.height, source.weight, source.smoker, source.familyhistory, source.cholestlevs, source.bp, source.risk, source.update_timestamp);

--Truncate bronze batch once successfully loaded
TRUNCATE TABLE bronze_users;

-- COMMAND ----------

OPTIMIZE silver_users ;


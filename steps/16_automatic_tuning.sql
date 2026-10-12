-- TITLE: Step 16 - What runs automatically on Autonomous Database
-- USER: admin
-- The maintenance-window jobs. The SQL tuning advisor client says ENABLED.
SELECT client_name, status, attributes
  FROM dba_autotask_client
 ORDER BY client_name;

-- But the task it would run has never been created here.
SELECT task_name, advisor_name, status
  FROM dba_advisor_tasks
 WHERE task_name LIKE 'SYS_AUTO%'
 ORDER BY task_name;

SELECT DBMS_AUTO_SQLTUNE.REPORT_AUTO_TUNING_TASK AS report FROM dual;

-- Automatic indexing exists and is switched off.
SELECT parameter_name, parameter_value
  FROM dba_auto_index_config
 WHERE parameter_name IN ('AUTO_INDEX_MODE', 'AUTO_INDEX_SCHEMA', 'AUTO_INDEX_RETENTION_FOR_AUTO')
 ORDER BY parameter_name;

-- Every profile on this database was accepted by hand. None are automatic.
SELECT type, status, COUNT(*) AS profiles
  FROM dba_sql_profiles
 GROUP BY type, status;

-- The global statistics preferences on this instance. SIZE 254 is not the Oracle default,
-- and it decides what a gather with no METHOD_OPT builds.
SELECT DBMS_STATS.GET_PREFS('METHOD_OPT')    AS method_opt,
       DBMS_STATS.GET_PREFS('GRANULARITY')   AS granularity,
       DBMS_STATS.GET_PREFS('NO_INVALIDATE') AS no_invalidate
  FROM dual;

-- What that preference does: a scratch table gathered with no options at all.
CREATE TABLE histogram_probe AS
SELECT order_id, status FROM tunedemo.orders WHERE ROWNUM <= 200000;

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'HISTOGRAM_PROBE');
END;
/

SELECT column_name, num_distinct, histogram
  FROM user_tab_col_statistics
 WHERE table_name = 'HISTOGRAM_PROBE'
 ORDER BY column_name;

DROP TABLE histogram_probe PURGE;

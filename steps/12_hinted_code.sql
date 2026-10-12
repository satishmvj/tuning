-- TITLE: Step 12 - Overriding a hint in code you cannot change
-- The nightly export still says FULL(o). The advisor is asked about it as it stands.
DECLARE
  l_sql_id VARCHAR2(13);
  l_task   VARCHAR2(64);
BEGIN
  SELECT sql_id INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE '%legacy-export {RUN} */'
     AND ROWNUM = 1;
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => l_sql_id, task_name => 'LEGACY_EXPORT_TASK');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK('LEGACY_EXPORT_TASK');
END;
/

SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('LEGACY_EXPORT_TASK', section => 'FINDINGS') AS report
  FROM dual;

BEGIN
  DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => 'LEGACY_EXPORT_TASK',
                                  name      => 'TUNEDEMO_LEGACY',
                                  replace   => TRUE);
  DBMS_SQLTUNE.PACK_STGTAB_SQLPROF(profile_name       => 'TUNEDEMO_LEGACY',
                                   staging_table_name => 'PROFILE_STAGE');
END;
/

-- The first hint is the one that matters: the statement's own hints are ignored.
SELECT x.hint
  FROM (SELECT comp_data FROM profile_stage
         WHERE obj_name = 'TUNEDEMO_LEGACY' AND ROWNUM = 1) s,
       XMLTABLE('/outline_data/hint' PASSING XMLTYPE(s.comp_data)
                COLUMNS hint VARCHAR2(120) PATH '.') x;

ALTER SESSION SET statistics_level = ALL;

SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

-- The hint report shows FULL(o) as unused, and the Note shows why.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST +HINT_REPORT'));

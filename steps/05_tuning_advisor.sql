-- TITLE: Step 5 - Asking the SQL Tuning Advisor
-- A tuning task takes a statement straight from the cursor cache by its SQL_ID.
DECLARE
  l_sql_id VARCHAR2(13);
  l_task   VARCHAR2(64);
BEGIN
  SELECT sql_id INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
     AND ROWNUM = 1;

  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(
              sql_id     => l_sql_id,
              scope      => DBMS_SQLTUNE.SCOPE_COMPREHENSIVE,
              time_limit => 300,
              task_name  => 'PENDING_REPORT_TASK',
              description => 'Operations pending-orders report');

  DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => 'PENDING_REPORT_TASK');
END;
/

SELECT task_name, advisor_name, status, execution_start, execution_end
  FROM user_advisor_tasks
 WHERE task_name = 'PENDING_REPORT_TASK';

-- The report: findings, the recommendation, and the plan it would give you.
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('PENDING_REPORT_TASK') AS report FROM dual;

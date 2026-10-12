-- TITLE: Step 10 - Fixing the cause instead: a histogram
-- The profile was compensating for statistics that did not describe the data.
BEGIN
  DBMS_SQLTUNE.DROP_SQL_PROFILE('TUNEDEMO_PENDING');
END;
/

-- A frequency histogram on STATUS. NO_INVALIDATE => FALSE replaces the cursors now;
-- the default invalidates them gradually, and the old plans can linger for hours.
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS',
                                method_opt    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS status SIZE 254',
                                no_invalidate => FALSE);
END;
/

SELECT column_name, num_distinct, histogram, num_buckets
  FROM user_tab_col_statistics
 WHERE table_name = 'ORDERS' AND column_name = 'STATUS';

SELECT endpoint_actual_value AS status,
       endpoint_number - NVL(LAG(endpoint_number) OVER (ORDER BY endpoint_number), 0) AS rows_counted
  FROM user_histograms
 WHERE table_name = 'ORDERS' AND column_name = 'STATUS'
 ORDER BY endpoint_number;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'CANCELLED'
 GROUP BY c.city
 ORDER BY c.city;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'DELIVERED'
 GROUP BY c.city
 ORDER BY c.city;

-- No profile anywhere, and each value gets the plan that suits it.
SELECT REGEXP_SUBSTR(sql_text, q'['[A-Z]+']') AS literal, child_number AS child,
       plan_hash_value AS plan_hash, sql_profile,
       ROUND(buffer_gets / executions) AS gets_per_exec,
       ROUND(elapsed_time / executions / 1000, 1) AS ms_per_exec
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
   AND object_status = 'VALID'
 ORDER BY literal, child_number;

-- Ask the advisor again about the statement it tuned in step 5.
DECLARE
  l_sql_id VARCHAR2(13);
  l_task   VARCHAR2(64);
BEGIN
  SELECT sql_id INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
     AND sql_text LIKE '%''PENDING''%'
     AND ROWNUM = 1;
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => l_sql_id, task_name => 'PENDING_REPORT_RECHECK');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK('PENDING_REPORT_RECHECK');
END;
/

SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('PENDING_REPORT_RECHECK', section => 'FINDINGS') AS report
  FROM dual;

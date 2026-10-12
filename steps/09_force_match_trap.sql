-- TITLE: Step 9 - force_match, and the value it should never have matched
-- The obvious fix: accept the same profile again with force_match. It is refused.
BEGIN
  DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name   => 'PENDING_REPORT_TASK',
                                  name        => 'TUNEDEMO_PENDING',
                                  replace     => TRUE,
                                  force_match => TRUE);
END;
/

-- The signature changes, so REPLACE cannot apply. Drop it and accept it again.
BEGIN
  DBMS_SQLTUNE.DROP_SQL_PROFILE('TUNEDEMO_PENDING');
  DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name   => 'PENDING_REPORT_TASK',
                                  name        => 'TUNEDEMO_PENDING',
                                  replace     => TRUE,
                                  force_match => TRUE);
END;
/

SELECT name, signature, force_matching FROM dba_sql_profiles WHERE name = 'TUNEDEMO_PENDING';

ALTER SESSION SET statistics_level = ALL;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'CANCELLED'
 GROUP BY c.city
 ORDER BY c.city;

-- And the report for delivered orders - 99% of the table - picks up the same profile.
SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'DELIVERED'
 GROUP BY c.city
 ORDER BY c.city;

-- SCALE_ROWS=0.004 is applied to 990,000 rows. The optimizer expects about 1,000.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST'));

SELECT REGEXP_SUBSTR(sql_text, q'['[A-Z]+']') AS literal, child_number AS child,
       plan_hash_value AS plan_hash, sql_profile,
       ROUND(buffer_gets / executions) AS gets_per_exec,
       ROUND(elapsed_time / executions / 1000, 1) AS ms_per_exec
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
 ORDER BY literal, child_number;

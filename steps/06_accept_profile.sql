-- TITLE: Step 6 - Accepting the SQL profile
-- The advisor's own suggested call, with a name we choose instead of SYS_SQLPROF_...
BEGIN
  DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(
    task_name   => 'PENDING_REPORT_TASK',
    name        => 'TUNEDEMO_PENDING',
    description => 'Pending-orders report: corrected cardinality on STATUS',
    replace     => TRUE);
END;
/

SELECT name, category, status, type, force_matching, created
  FROM dba_sql_profiles
 WHERE name = 'TUNEDEMO_PENDING';

-- The application changes nothing. The same text arrives, and the profile is applied.
ALTER SESSION SET statistics_level = ALL;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

-- E-Rows now matches A-Rows, the index is used, and the Note names the profile.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST'));

-- Before and after, per child cursor: the profile is recorded against the cursor it built.
SELECT child_number AS child, plan_hash_value AS plan_hash, sql_profile, executions AS execs,
       ROUND(buffer_gets / executions) AS gets_per_exec
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
 ORDER BY child_number;

-- TITLE: Step 14 - Tuning a workload, not a statement
-- A new release ships four more statements. Nobody has looked at their plans.
SELECT /* customer-search {RUN} */ customer_id, full_name
  FROM customers
 WHERE UPPER(full_name) = 'CUSTOMER 4242';

SELECT /* order-by-ref {RUN} */ COUNT(*) AS orders, SUM(amount) AS amount
  FROM orders
 WHERE TO_CHAR(order_id) = '424242';

SELECT /* open-customers {RUN} */ COUNT(*) AS customers
  FROM (SELECT customer_id FROM orders WHERE status = 'PENDING'
        UNION
        SELECT customer_id FROM orders WHERE status = 'CANCELLED');

SELECT /* pune-backlog {RUN} */ COUNT(*) AS backlog
  FROM customers c, orders o
 WHERE c.city = 'Pune'
   AND o.status = 'PENDING';

-- A SQL tuning set captures statements with their execution statistics. The filter is
-- anchored on purpose: a bare LIKE '%tag%' also captured the loading query itself.
DECLARE
  l_cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => 'RELEASE_WORKLOAD',
                             description => 'Every application statement in this run');
  OPEN l_cur FOR
    SELECT VALUE(p)
      FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE(
             basic_filter => q'[parsing_schema_name = 'TUNEDEMO'
                                AND sql_text LIKE 'SELECT /*%{RUN}%']')) p;
  DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => 'RELEASE_WORKLOAD', populate_cursor => l_cur);
END;
/

SELECT sql_id, SUBSTR(sql_text, 1, 44) AS sql_text, executions AS execs,
       ROUND(buffer_gets / GREATEST(executions, 1)) AS gets_per_exec
  FROM user_sqlset_statements
 WHERE sqlset_name = 'RELEASE_WORKLOAD'
 ORDER BY gets_per_exec DESC;

-- One advisor task over the whole set.
DECLARE
  l_task VARCHAR2(64);
BEGIN
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(sqlset_name => 'RELEASE_WORKLOAD',
                                            task_name   => 'RELEASE_WORKLOAD_TASK',
                                            time_limit  => 600);
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK('RELEASE_WORKLOAD_TASK');
END;
/

-- The triage view: every recommendation, per statement, with its estimated benefit.
SELECT NVL(REGEXP_SUBSTR(DBMS_LOB.SUBSTR(s.sql_text, 400), '/\* ([a-z-]+) run-', 1, 1, NULL, 1),
           '(whole set)') AS statement,
       r.type AS recommendation,
       ROUND(r.benefit / 100, 2) AS benefit_pct
  FROM user_advisor_recommendations r
  JOIN user_advisor_findings f ON f.task_id = r.task_id AND f.finding_id = r.finding_id
  JOIN user_advisor_objects o  ON o.task_id = f.task_id AND o.object_id = f.object_id
  LEFT JOIN user_sqlset_statements s
    ON s.sqlset_name = 'RELEASE_WORKLOAD' AND s.sql_id = o.attr1
 WHERE r.task_name = 'RELEASE_WORKLOAD_TASK'
 ORDER BY statement, r.type;

-- The findings behind them, in the advisor's own words.
SELECT NVL(REGEXP_SUBSTR(DBMS_LOB.SUBSTR(s.sql_text, 400), '/\* ([a-z-]+) run-', 1, 1, NULL, 1),
           '(whole set)') AS statement,
       f.message
  FROM user_advisor_findings f
  JOIN user_advisor_objects o ON o.task_id = f.task_id AND o.object_id = f.object_id
  LEFT JOIN user_sqlset_statements s
    ON s.sqlset_name = 'RELEASE_WORKLOAD' AND s.sql_id = o.attr1
 WHERE f.task_name = 'RELEASE_WORKLOAD_TASK'
 ORDER BY statement, f.finding_id;

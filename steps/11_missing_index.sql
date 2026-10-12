-- TITLE: Step 11 - When the advisor's answer is an index
-- The customer screen from step 2: 22 rows, found by reading every block of ORDERS.
DECLARE
  l_sql_id VARCHAR2(13);
  l_task   VARCHAR2(64);
BEGIN
  SELECT sql_id INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE 'SELECT /* customer-orders {RUN} */%'
     AND ROWNUM = 1;
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => l_sql_id, task_name => 'CUSTOMER_ORDERS_TASK');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK('CUSTOMER_ORDERS_TASK');
END;
/

SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('CUSTOMER_ORDERS_TASK', section => 'FINDINGS') AS report
  FROM dual;

-- The advisor names it IDX$$_...; the DDL is the recommendation, the name is ours.
CREATE INDEX orders_customer_ix ON orders (customer_id);

SELECT /* customer-orders {RUN} */ COUNT(*) AS orders, SUM(amount) AS amount,
       MAX(order_date) AS last_order
  FROM orders
 WHERE customer_id = 4242;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC ROWS'));

-- Creating the index invalidated the old cursor; the new one reads 26 blocks, not 22,000.
SELECT child_number AS child, plan_hash_value AS plan_hash, object_status,
       executions AS execs, ROUND(buffer_gets / executions) AS gets_per_exec
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /* customer-orders {RUN} */%'
 ORDER BY last_load_time;

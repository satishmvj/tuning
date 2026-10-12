-- TITLE: Step 2 - Three statements from the application, and finding the expensive one
-- The report the operations team runs every few minutes.
SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

-- The customer screen.
SELECT /* customer-orders {RUN} */ COUNT(*) AS orders, SUM(amount) AS amount,
       MAX(order_date) AS last_order
  FROM orders
 WHERE customer_id = 4242;

-- A nightly export somebody hinted years ago. The code cannot be changed.
SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

-- Where to start tuning: the cursor cache, ranked by logical reads per execution.
-- Three statements that each return a handful of rows read 22,000 blocks apiece.
SELECT sql_id, plan_hash_value AS plan_hash, executions AS execs,
       ROUND(buffer_gets / executions)        AS gets_per_exec,
       ROUND(elapsed_time / executions / 1000, 1) AS ms_per_exec,
       SUBSTR(sql_text, 1, 42)                AS sql_text
  FROM v$sql
 WHERE parsing_schema_name = 'TUNEDEMO'
   AND sql_text LIKE '%{RUN}%'
   AND sql_text NOT LIKE '%v$sql%'
 ORDER BY gets_per_exec DESC;

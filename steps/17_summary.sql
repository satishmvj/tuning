-- TITLE: Step 17 - Everything the walkthrough left behind
-- The profiles: one from the advisor that survived, one written by hand.
SELECT name, type, category, status, force_matching, description
  FROM dba_sql_profiles
 ORDER BY created;

-- Every advisor task, and what it recommended.
SELECT t.task_name,
       t.status,
       (SELECT COUNT(*) FROM user_advisor_findings f WHERE f.task_id = t.task_id)        AS findings,
       (SELECT LISTAGG(DISTINCT r.type, ', ') WITHIN GROUP (ORDER BY r.type)
          FROM user_advisor_recommendations r WHERE r.task_id = t.task_id)               AS recommended
  FROM user_advisor_tasks t
 ORDER BY t.task_id;

-- The index the advisor asked for, and its cost in space.
SELECT i.index_name, c.column_name, s.bytes / 1048576 AS mb
  FROM user_indexes i
  JOIN user_ind_columns c ON c.index_name = i.index_name
  JOIN user_segments s    ON s.segment_name = i.index_name
 WHERE i.table_name = 'ORDERS'
 ORDER BY i.index_name;

-- Index DDL, statistics and profile changes all invalidated cursors along the way, so the
-- original workload is replayed once before the cursor cache is read.
SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'DELIVERED'
 GROUP BY c.city
 ORDER BY c.city;

SELECT /* customer-orders {RUN} */ COUNT(*) AS orders, SUM(amount) AS amount,
       MAX(order_date) AS last_order
  FROM orders
 WHERE customer_id = 4242;

SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

-- Where each application statement stands now, from the cursor cache. Step 2 had the
-- first three at 22,000 blocks per execution.
SELECT REGEXP_SUBSTR(sql_text, '/\* ([a-z-]+) run-', 1, 1, NULL, 1) AS statement,
       REGEXP_SUBSTR(sql_text, q'['[A-Z]+'|customer_id = [0-9]+]') AS predicate,
       plan_hash_value AS plan_hash, sql_profile,
       SUM(executions) AS execs,
       ROUND(SUM(buffer_gets) / GREATEST(SUM(executions), 1)) AS gets_per_exec,
       ROUND(SUM(elapsed_time) / GREATEST(SUM(executions), 1) / 1000, 1) AS ms_per_exec
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /*%{RUN}%'
   AND object_status = 'VALID'
 GROUP BY REGEXP_SUBSTR(sql_text, '/\* ([a-z-]+) run-', 1, 1, NULL, 1),
          REGEXP_SUBSTR(sql_text, q'['[A-Z]+'|customer_id = [0-9]+]'),
          plan_hash_value, sql_profile
 ORDER BY statement, predicate, plan_hash;

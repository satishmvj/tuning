-- TITLE: Step 3 - What the optimizer planned, and what actually happened
-- EXPLAIN PLAN is the optimizer's forecast. Nothing runs.
EXPLAIN PLAN FOR
SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC ROWS COST'));

-- Row-source statistics cost a little per row, so they are collected on request.
ALTER SESSION SET statistics_level = ALL;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'PENDING'
 GROUP BY c.city
 ORDER BY c.city;

-- The same plan with the truth alongside: E-Rows is the estimate, A-Rows what came back.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST'));

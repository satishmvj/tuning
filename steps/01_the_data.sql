-- TITLE: Step 1 - The data, and the skew the optimizer cannot see
-- A million orders, fifty thousand customers, statistics gathered a moment ago.
SELECT table_name, num_rows, blocks, last_analyzed
  FROM user_tables
 ORDER BY table_name;

-- The shape the optimizer has not been told about: one status is 99% of the table.
SELECT status,
       COUNT(*)                                            AS orders,
       ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 2)   AS pct
  FROM orders
 GROUP BY status
 ORDER BY orders DESC;

-- Two indexes, and none on ORDERS.CUSTOMER_ID - a foreign key nobody indexed.
SELECT i.table_name, i.index_name, c.column_name, i.uniqueness
  FROM user_indexes i
  JOIN user_ind_columns c ON c.index_name = i.index_name
 ORDER BY i.table_name, i.index_name;

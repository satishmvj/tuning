-- TITLE: Step 4 - Where 250,000 came from
-- The optimizer knows four distinct statuses and nothing about how they are spread.
SELECT column_name, num_distinct, ROUND(density, 4) AS density, num_nulls, histogram
  FROM user_tab_col_statistics
 WHERE table_name = 'ORDERS'
   AND column_name IN ('STATUS', 'CUSTOMER_ID', 'ORDER_DATE')
 ORDER BY column_name;

-- Without a histogram every value is assumed to be equally common:
-- rows / distinct values, for PENDING and for DELIVERED alike.
SELECT t.num_rows,
       s.num_distinct,
       t.num_rows / s.num_distinct                            AS estimated_rows,
       (SELECT COUNT(*) FROM orders WHERE status = 'PENDING')   AS actual_pending,
       (SELECT COUNT(*) FROM orders WHERE status = 'DELIVERED') AS actual_delivered
  FROM user_tables t
  JOIN user_tab_col_statistics s ON s.table_name = t.table_name
 WHERE t.table_name = 'ORDERS'
   AND s.column_name = 'STATUS';

-- The statistics are current, so "gather statistics" is not the answer anybody will
-- give you. The estimate is wrong because of what was gathered, not when.
SELECT table_name, stale_stats, last_analyzed
  FROM user_tab_statistics
 WHERE table_name IN ('ORDERS', 'CUSTOMERS');

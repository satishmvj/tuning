-- TITLE: Step 8 - Change one literal and the profile is gone
-- The same report for cancelled orders. 4,000 rows, still a tiny share of the table.
ALTER SESSION SET statistics_level = ALL;

SELECT /* pending-report {RUN} */ c.city, COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 WHERE o.status = 'CANCELLED'
 GROUP BY c.city
 ORDER BY c.city;

-- Full scans again, and no Note: the profile was never considered.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC ROWS NOTE'));

-- A profile is attached to a signature. The exact signature changes with any literal;
-- the force-matching signature treats literals as binds and is the same for both.
SELECT REGEXP_SUBSTR(sql_text, q'['[A-Z]+']') AS literal, child_number AS child,
       exact_matching_signature, force_matching_signature, sql_profile
  FROM v$sql
 WHERE sql_text LIKE 'SELECT /* pending-report {RUN} */%'
 ORDER BY literal, child_number;

SELECT name, signature, force_matching
  FROM dba_sql_profiles
 WHERE name = 'TUNEDEMO_PENDING';

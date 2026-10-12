-- TITLE: Step 13 - Writing a SQL profile by hand
-- Another legacy statement, with a hint that forbids the index added in step 11.
-- The customer id changes on every call, so the profile must force-match.
SELECT /*+ NO_INDEX(o orders_customer_ix) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.customer_id = 777 /* legacy-lookup {RUN} */;

-- IMPORT_SQL_PROFILE takes the text and a list of hints you choose. It is how a plan is
-- carried from one database to another, and how a known fix is applied without the advisor.
DECLARE
  l_text CLOB;
BEGIN
  SELECT sql_fulltext INTO l_text
    FROM v$sql
   WHERE sql_text LIKE '%legacy-lookup {RUN} */'
     AND ROWNUM = 1;

  DBMS_SQLTUNE.IMPORT_SQL_PROFILE(
    sql_text    => l_text,
    profile     => sqlprof_attr(
                     'BEGIN_OUTLINE_DATA',
                     'IGNORE_OPTIM_EMBEDDED_HINTS',
                     'INDEX(@"SEL$1" "O"@"SEL$1" ("ORDERS"."CUSTOMER_ID"))',
                     'END_OUTLINE_DATA'),
    name        => 'TUNEDEMO_MANUAL',
    description => 'Legacy lookup: use ORDERS_CUSTOMER_IX despite NO_INDEX',
    force_match => TRUE,
    replace     => TRUE);
END;
/

SELECT name, type, status, force_matching, description
  FROM dba_sql_profiles
 ORDER BY created;

-- Two different customers, two different statements, one profile.
SELECT /*+ NO_INDEX(o orders_customer_ix) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.customer_id = 777 /* legacy-lookup {RUN} */;

SELECT /*+ NO_INDEX(o orders_customer_ix) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.customer_id = 31337 /* legacy-lookup {RUN} */;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC NOTE'));

SELECT REGEXP_SUBSTR(sql_text, 'customer_id = [0-9]+') AS predicate, child_number AS child,
       plan_hash_value AS plan_hash, sql_profile, object_status,
       executions AS execs, ROUND(buffer_gets / executions) AS gets_per_exec
  FROM v$sql
 WHERE sql_text LIKE '%legacy-lookup {RUN} */'
 ORDER BY predicate, last_load_time;

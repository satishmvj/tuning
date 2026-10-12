-- TITLE: Step 15 - Parking, disabling and dropping a profile
-- Move the legacy profile into a TEST category: it still exists, and nobody uses it.
BEGIN
  DBMS_SQLTUNE.ALTER_SQL_PROFILE(name           => 'TUNEDEMO_LEGACY',
                                 attribute_name => 'CATEGORY',
                                 value          => 'TEST');
END;
/

SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC NOTE'));

-- On a normal database one session would now opt in to try it. Not on this one - the
-- parameter is locked, for ADMIN as well, so a category can park a profile but not test it.
ALTER SESSION SET sqltune_category = 'TEST';

-- Back to DEFAULT, and the profile is in use again.
BEGIN
  DBMS_SQLTUNE.ALTER_SQL_PROFILE('TUNEDEMO_LEGACY', 'CATEGORY', 'DEFAULT');
END;
/

SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC NOTE'));

-- Disabled: kept, out of every plan, and one call from coming back.
BEGIN
  DBMS_SQLTUNE.ALTER_SQL_PROFILE('TUNEDEMO_LEGACY', 'STATUS', 'DISABLED');
END;
/

SELECT name, category, status, force_matching, last_modified
  FROM dba_sql_profiles
 ORDER BY created;

SELECT /*+ FULL(o) */ COUNT(*) AS orders, SUM(o.amount) AS amount
  FROM orders o
 WHERE o.status = 'SHIPPED'
   AND o.order_date >= DATE '2025-06-01' /* legacy-export {RUN} */;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC NOTE'));

-- A profile is exported before it is dropped - the staging table from step 7 has it.
BEGIN
  DBMS_SQLTUNE.ALTER_SQL_PROFILE('TUNEDEMO_LEGACY', 'STATUS', 'ENABLED');
  DBMS_SQLTUNE.DROP_SQL_PROFILE('TUNEDEMO_LEGACY');
END;
/

SELECT (SELECT COUNT(*) FROM dba_sql_profiles WHERE name = 'TUNEDEMO_LEGACY')       AS in_database,
       (SELECT COUNT(*) FROM profile_stage WHERE obj_name = 'TUNEDEMO_LEGACY')       AS rows_in_stage
  FROM dual;

-- And back from the staging table, exactly as it was packed.
BEGIN
  DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF(profile_name       => 'TUNEDEMO_LEGACY',
                                     replace            => TRUE,
                                     staging_table_name => 'PROFILE_STAGE');
END;
/

SELECT name, category, status, force_matching
  FROM dba_sql_profiles
 ORDER BY created;

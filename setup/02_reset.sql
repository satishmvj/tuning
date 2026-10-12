-- SQL profiles belong to the database, not to a schema, and they match on SQL text, not
-- on table ids - so a rebuilt table would pick up an old profile. Drop them by name first.
BEGIN
  FOR p IN (SELECT name FROM dba_sql_profiles WHERE name LIKE 'TUNEDEMO%') LOOP
    DBMS_SQLTUNE.DROP_SQL_PROFILE(p.name);
  END LOOP;
  FOR t IN (SELECT task_name FROM user_advisor_tasks) LOOP
    DBMS_SQLTUNE.DROP_TUNING_TASK(t.task_name);
  END LOOP;
  FOR s IN (SELECT name FROM user_sqlset) LOOP
    DBMS_SQLTUNE.DROP_SQLSET(s.name);
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

SELECT (SELECT COUNT(*) FROM user_tables)                                       AS tables_left,
       (SELECT COUNT(*) FROM dba_sql_profiles WHERE name LIKE 'TUNEDEMO%')      AS profiles_left,
       (SELECT COUNT(*) FROM user_advisor_tasks)                                AS tasks_left,
       (SELECT COUNT(*) FROM user_sqlset)                                       AS sqlsets_left
  FROM dual;

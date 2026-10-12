-- Run as ADMIN, once. TUNEDEMO owns the data and tunes its own statements, so every
-- privilege the advisor and the profile calls need is granted here, explicitly.
DROP USER tunedemo CASCADE;

CREATE USER tunedemo IDENTIFIED BY "Tun3#Advisor2026Zz" QUOTA UNLIMITED ON DATA;
GRANT CONNECT, RESOURCE TO tunedemo;
GRANT UNLIMITED TABLESPACE TO tunedemo;

-- SELECT ANY DICTIONARY is not enough here, and it fails in four different ways: V$SQL
-- raises ORA-00942, DISPLAY_CURSOR prints "User has no SELECT privilege on V$SESSION",
-- DBA_SQL_PROFILES does not exist, and a tuning task on a SQL_ID raises ORA-13773
-- "insufficient privileges to select data from the cursor cache".
-- SELECT_CATALOG_ROLE fixes all of them at once.
GRANT SELECT ANY DICTIONARY TO tunedemo;
GRANT SELECT_CATALOG_ROLE TO tunedemo;

-- The SQL Tuning Advisor is an advisor task; ADVISOR is what lets a user create one.
GRANT ADVISOR TO tunedemo;
-- Accepting, altering and dropping SQL profiles.
GRANT ADMINISTER SQL MANAGEMENT OBJECT TO tunedemo;
-- SQL tuning sets, for tuning a workload rather than one statement.
GRANT ADMINISTER SQL TUNING SET TO tunedemo;

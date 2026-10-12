-- TITLE: Step 7 - What a SQL profile actually contains
-- The hints are not in any view a user can query on Autonomous Database: SYS.SQLOBJ$DATA
-- cannot even be granted. Packing the profile into a staging table - the supported way to
-- move one between databases - exposes them.
BEGIN
  DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF(table_name => 'PROFILE_STAGE');
  DBMS_SQLTUNE.PACK_STGTAB_SQLPROF(profile_name       => 'TUNEDEMO_PENDING',
                                   staging_table_name => 'PROFILE_STAGE');
END;
/

SELECT obj_name, obj_type, category, COUNT(*) AS rows_packed
  FROM profile_stage
 GROUP BY obj_name, obj_type, category;

-- Not a plan. Corrections: scale the row estimates for ORDERS by 0.004 - 1,000 / 250,000.
SELECT x.hint
  FROM (SELECT comp_data FROM profile_stage
         WHERE obj_name = 'TUNEDEMO_PENDING' AND ROWNUM = 1) s,
       XMLTABLE('/outline_data/hint' PASSING XMLTYPE(s.comp_data)
                COLUMNS hint VARCHAR2(120) PATH '.') x;

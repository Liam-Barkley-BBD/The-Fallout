---------------------------------------------------------------
-- # HELPER FUNCTION
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_role_helper 
(
  role_name TEXT,
  role_password TEXT DEFAULT NULL
)
RETURNS void
AS $$
BEGIN
  IF role_password IS NULL THEN
    EXECUTE 'CREATE ROLE ' || quote_ident(role_name);
  ELSE
    EXECUTE 'CREATE ROLE ' || quote_ident(role_name) || ' LOGIN PASSWORD ' || quote_literal(role_password);
  END IF;

  EXCEPTION WHEN duplicate_object 
  THEN 
    RAISE NOTICE '%. Revoking all privileges from role.', SQLERRM USING ERRCODE = SQLSTATE;
    -- revoke everything to override any grants from previous migrations
    EXECUTE 'REVOKE ALL PRIVILEGES ON DATABASE "${DB_NAME}" FROM ' || quote_ident(role_name);
    EXECUTE 'REVOKE ALL PRIVILEGES ON SCHEMA public FROM ' || quote_ident(role_name);
    EXECUTE 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM ' || quote_ident(role_name);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE create_role
(
  role_name TEXT,
  role_password TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM create_role_helper(role_name => role_name, role_password => role_password);
END;
$$;

---------------------------------------------------------------
-- # DATABASE ADMIN SECTION
---------------------------------------------------------------
-- ## GROUP
CALL create_role(role_name => 'FalloutAdminGroup');

-- ### DB LEVEL PERMISSIONS
-- Allow creation of temporary tables on the database
GRANT TEMPORARY
ON DATABASE "${DB_NAME}" 
TO FalloutAdminGroup;

-- ### SCHEMA LEVEL PERMISSIONS
-- Allow creation and usage of database objects in the public schema
GRANT CREATE, USAGE
ON SCHEMA public 
TO FalloutAdminGroup;

-- ### OBJECT LEVEL PERMISSIONS
-- allow all except deleting on all tables in the public schema
GRANT SELECT, INSERT, UPDATE, REFERENCES, TRIGGER, MAINTAIN
ON ALL TABLES IN SCHEMA public 
TO FalloutAdminGroup;

-- allow all (Execute) on all functions in the schema
GRANT ALL
ON ALL FUNCTIONS IN SCHEMA public 
TO FalloutAdminGroup;

-- allow all (Execute) on all procedures in the schema
GRANT ALL 
ON ALL PROCEDURES IN SCHEMA public 
TO FalloutAdminGroup;

-- allow all (Execute) on all routines in the schema
GRANT ALL
ON ALL ROUTINES IN SCHEMA public 
TO FalloutAdminGroup;

-- ## USER
CALL create_role(role_name => 'FalloutAdmin', role_password => '${ADMIN_PASS}');

GRANT CONNECT
ON DATABASE "${DB_NAME}"
TO FalloutAdmin;

GRANT FalloutAdminGroup 
TO FalloutAdmin;

---------------------------------------------------------------
-- # MANAGER SECTION
---------------------------------------------------------------
-- ## GROUP
CALL create_role(role_name => 'ManagerGroup');

-- ### DB LEVEL PERMISSIONS
-- none for manager

-- ### SCHEMA LEVEL PERMISSIONS
-- Allow usage of objects in the public schema
GRANT USAGE
ON SCHEMA public
TO ManagerGroup;

-- ### OBJECT LEVEL PERMISSIONS
-- allow select, insert, and update on all tables in public schema
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO ManagerGroup;

-- Allow all on all functions in public schema
GRANT ALL
ON ALL FUNCTIONS IN SCHEMA public
TO ManagerGroup;

-- Allow all on all procedures in public schema
GRANT ALL
ON ALL PROCEDURES IN SCHEMA public
TO ManagerGroup;

-- ## USER
CALL create_role(role_name => 'ManagerApp', role_password => '${MANAGER_APP_PASS}');

GRANT CONNECT
ON DATABASE "${DB_NAME}"
TO ManagerApp;

GRANT ManagerGroup 
TO ManagerApp;

---------------------------------------------------------------
-- # SURVIVOR SECTION
---------------------------------------------------------------
-- ## GROUP
CALL create_role(role_name => 'SurvivorGroup');

-- ### DB LEVEL PERMISSIONS
-- none for survivors

-- ### SCHEMA LEVEL PERMISSIONS
-- allow usage of public schema
GRANT USAGE
ON SCHEMA public
TO SurvivorGroup;

-- ### OBJECT LEVEL PERMISSIONS
-- allow select, insert, and update on all tables in public schema
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO SurvivorGroup;

-- allow all on all functions in public schema
GRANT ALL PRIVILEGES
ON ALL FUNCTIONS IN SCHEMA public
TO SurvivorGroup;

-- allow all on all procedures in public schema
GRANT ALL PRIVILEGES
ON ALL PROCEDURES IN SCHEMA public
TO SurvivorGroup;

-- ## USER
CALL create_role(role_name => 'SurvivorApp', role_password => '${SURVIVOR_APP_PASS}');

GRANT CONNECT
ON DATABASE "${DB_NAME}"
TO SurvivorApp;

GRANT SurvivorGroup 
TO SurvivorApp;

---------------------------------------------------------------
-- # REPORTING SECTION
---------------------------------------------------------------
-- ## GROUP
CALL create_role(role_name => 'ReportingGroup');

-- ### DB LEVEL PERMISSIONS
-- none for reporters

-- ### SCHEMA LEVEL PERMISSIONS
-- allow usage of public schema
GRANT USAGE
ON SCHEMA public
TO ReportingGroup;

-- ### OBJECT LEVEL PERMISSIONS
-- allow select only on all tables
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO ReportingGroup;

-- ## USER
CALL create_role(role_name => 'ReportingApp', role_password => '${REPORTING_APP_PASS}');

GRANT CONNECT ON DATABASE "${DB_NAME}" TO ReportingApp;
GRANT ReportingGroup TO ReportingApp;

---------------------------------------------------------------
-- # CLEANUP
---------------------------------------------------------------
DROP FUNCTION create_role_helper(TEXT, TEXT);
DROP PROCEDURE create_role(TEXT, TEXT);
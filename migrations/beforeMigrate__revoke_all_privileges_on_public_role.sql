-- default roles not allowed to create schemas in db, connect to db, create temporary objects in db
REVOKE CREATE ON DATABASE "${DB_NAME}" FROM PUBLIC;
REVOKE CONNECT ON DATABASE "${DB_NAME}" FROM public;
REVOKE TEMPORARY ON DATABASE "${DB_NAME}" FROM public;

-- default roles not allowed to create objects in public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

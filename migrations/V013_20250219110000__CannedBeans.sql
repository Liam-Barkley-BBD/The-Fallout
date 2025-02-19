CREATE OR REPLACE FUNCTION ValidateCannedBeanData()
RETURNS TRIGGER AS $$
BEGIN
    NEW."BeanType" := TRIM(NEW."BeanType");

    IF NOT ValidName(NEW."BeanType") THEN
        RAISE EXCEPTION
        '"BeanType" must be non-empty and only contain alphabetical letters';
    END IF;

    IF NEW."Grams" <= 0 THEN
        RAISE EXCEPTION '"Grams" has to be positive';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ValidateCannedBean BEFORE INSERT OR UPDATE ON "CannedBeans"
FOR EACH ROW EXECUTE FUNCTION ValidateCannedBeanData();

CREATE OR REPLACE PROCEDURE InsertCannedBean(
    IN P_BeanType VARCHAR(128),
    IN P_Grams FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Inserting into CannedBeans Table
    INSERT INTO "CannedBeans" ("BeanType", "Grams")
    VALUES (P_BeanType, P_Grams);

    -- Success!
    RAISE NOTICE 'Successfully inserted % (% grams)', P_BeanType, P_Grams;

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            ROLLBACK;
            RAISE EXCEPTION 'Error inserting into "CannedBeans": %',
            SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE UpdateCannedBean(
    IN P_CannedBeanID INTEGER,
    IN P_BeanType VARCHAR(128) DEFAULT NULL,
    IN P_Grams FLOAT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT IdExists(P_CannedBeanID, 'CannedBeanID', 'CannedBeans') THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    -- Performing the update
    UPDATE "CannedBeans"
    SET
        "BeanType" = COALESCE(P_BeanType, "BeanType"),
        "Grams" = COALESCE(P_Grams, "Grams")
    WHERE "CannedBeanID" = P_CannedBeanID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated CannedBeanID %', P_CannedBeanID;
    
    EXCEPTION
        WHEN others THEN
            -- Not success! :( Something went wrong
            ROLLBACK;
            RAISE EXCEPTION 'Error updating canned bean %: %',
                P_CannedBeanID, SQLERRM;
END;
$$;

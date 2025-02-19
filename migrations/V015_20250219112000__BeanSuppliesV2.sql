CREATE OR REPLACE FUNCTION ValidateBeanSupplyData()
RETURNS TRIGGER AS $$
BEGIN
        -- Checking if the ShelterID exists
    IF NOT IdExists(NEW."ShelterID", 'ShelterID', 'Shelters') THEN
        RAISE EXCEPTION 'ShelterID % does not exist', NEW."ShelterID";
    END IF;
    
    -- Checking if CannedBeanID exists
    IF NOT IdExists(NEW."CannedBeanID", 'CannedBeanID', 'CannedBeans') THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', NEW."CannedBeanID";
    END IF;

    IF NEW."ConsumedDate" IS NOT NULL AND NEW."ConsumedDate" > CURRENT_DATE THEN
        RAISE EXCEPTION 'ConsumedDate cannot be in the future';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ValidateBeanSupply BEFORE INSERT OR UPDATE ON "BeanSupplies"
FOR EACH ROW EXECUTE FUNCTION ValidateBeanSupplyData();

CREATE OR REPLACE PROCEDURE InsertBeanSupply(
    IN P_ShelterID INTEGER,
    IN P_CannedBeanID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Inserting the record
    INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID")
    VALUES (P_ShelterID, P_CannedBeanID);

    -- Success!
    RAISE NOTICE 'Successfully inserted into BeanSupplies';

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            ROLLBACK;
            RAISE EXCEPTION 'Error inserting into "BeanSupplies": %', SQLERRM;
END;
$$;

-- Update Procedure
CREATE OR REPLACE PROCEDURE UpdateBeanSupply(
    P_BeanSupplyID INTEGER,
    P_ShelterID INTEGER DEFAULT NULL,
    P_CannedBeanID INTEGER DEFAULT NULL,
    P_ConsumedDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Updating the record
    UPDATE "BeanSupplies"
    SET "ShelterID" = COALESCE(P_ShelterID, "ShelterID"),
        "CannedBeanID" = COALESCE(P_CannedBeanID, "CannedBeanID"),
        "ConsumedDate" = COALESCE(P_ConsumedDate, "ConsumedDate")
    WHERE "BeanSupplyID" = P_BeanSupplyID;

    -- Success!
    RAISE NOTICE 'Successfully updated record with BeanSupplieID %', P_BeanSupplyID;

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            RAISE EXCEPTION 'Error updating into "BeanSupplies": %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE ConsumeBeanSupply(
    p_BeanSupplyID INTEGER,
    p_ConsumedDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- If no date is provided, use the current date
    IF p_ConsumedDate IS NULL THEN
        p_ConsumedDate := CURRENT_DATE;
    END IF;

    -- Calling update procedure to set ConsumedDate
    CALL UpdateBeanSupply(
        p_BeanSupplyID,
        P_ConsumedDate => p_ConsumedDate
    );
END;
$$;

DROP VIEW ShelterBeanInventory;

CREATE OR REPLACE VIEW GlobalInventory AS
SELECT
    bs."ShelterID",
    COUNT(bs."CannedBeanID")::INTEGER AS "Number of Cans"
FROM "BeanSupplies" bs
JOIN "CannedBeans" cb ON bs."CannedBeanID" = cb."CannedBeanID"
WHERE bs."ConsumedDate" IS NULL
GROUP BY bs."ShelterID"
ORDER BY bs."ShelterID" ASC;

CREATE OR REPLACE VIEW GlobalBeanInventory AS
SELECT 
    bs."ShelterID", 
    cb."BeanType", 
    COUNT(bs."CannedBeanID")::INTEGER AS "Number of Cans",
    SUM(cb."Grams") AS "Grams"
FROM "BeanSupplies" bs
JOIN "CannedBeans" cb ON bs."CannedBeanID" = cb."CannedBeanID"
WHERE bs."ConsumedDate" IS NULL
GROUP BY bs."ShelterID", cb."BeanType"
ORDER BY bs."ShelterID" ASC;

CREATE OR REPLACE FUNCTION GetInventory(
    P_ShelterID INTEGER
)
RETURNS TABLE (
    "Available Cans" INTEGER
) AS $$
BEGIN
    IF NOT IdExists(P_ShelterID, 'ShelterID', 'Shelters') THEN
        RAISE EXCEPTION 'ShelterID % does not exist', P_ShelterID;
    END IF;

    RETURN QUERY SELECT "Number of Cans"
    AS "Available Cans"
    FROM GlobalInventory
    WHERE "ShelterID" = P_ShelterID;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetBeanInventory(
    P_ShelterID INTEGER
)
RETURNS TABLE (
    "Bean Type" VARCHAR(128),
    "Available Cans" INTEGER
) AS $$
BEGIN
    IF NOT IdExists(P_ShelterID, 'ShelterID', 'Shelters') THEN
        RAISE EXCEPTION 'ShelterID % does not exist', P_ShelterID;
    END IF;

    RETURN QUERY SELECT
        "BeanType" AS "Bean Type",
        "Number of Cans" AS "Available Cans"
    FROM GlobalBeanInventory
    WHERE "ShelterID" = P_ShelterID;
END;
$$ LANGUAGE plpgsql;
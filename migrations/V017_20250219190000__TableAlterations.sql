BEGIN;

ALTER TABLE "Survivors"
ADD COLUMN "BottleCaps" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "Shelters"
DROP COLUMN "SupplyVolume";

ALTER TABLE "Shelters"
ADD COLUMN "WeeklyLimit" INTEGER;


-- Drop existing trigger
DROP TRIGGER IF EXISTS ValidateRequestItem ON "BeanRequestItem";

-- Rename the table
ALTER TABLE "BeanRequestItem" RENAME TO "BeanRequestItems";

-- Recreate the trigger on the new table
CREATE TRIGGER ValidateRequestItem BEFORE INSERT ON "BeanRequestItems"
FOR EACH ROW EXECUTE FUNCTION ValidateRequestItemData();

-- Recreate InsertBeanRequestItem procedure with the new table name
CREATE OR REPLACE PROCEDURE InsertBeanRequestItem(
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER,
    IN P_BeanRequestID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "BeanRequestItems" ("CannedBeanID", "NumberOfCans", "BeanRequestID")
    VALUES (P_CannedBeanID, P_NumberOfCans, P_BeanRequestID);

    RAISE NOTICE 'Successfully inserted bean request item for request with 
    BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error inserting bean request item: %', SQLERRM;
END;
$$;

-- Recreate ApproveBeanRequest procedure with updated references
CREATE OR REPLACE PROCEDURE ApproveBeanRequest(
    IN P_RequestID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ApprovedFlag DATE;
    V_NumItems INTEGER;
    V_ShelterID INTEGER;
    V_SurvivorID INTEGER;
    V_SupplyID INTEGER;
    rec RECORD;
BEGIN
    IF NOT IdExists(P_RequestID, 'BeanRequestID', 'BeanRequests') THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_RequestID;
    END IF;

    SELECT "ApprovalDate" INTO V_ApprovedFlag FROM "BeanRequests"
    WHERE "BeanRequestID" = P_RequestID;

    IF V_ApprovedFlag IS NOT NULL THEN
        RAISE EXCEPTION 'BeanRequest % has already been approved',
        P_RequestID;
    END IF;

    CALL UpdateBeanRequest(P_RequestID, P_ApprovalDate => CURRENT_DATE);

    SELECT "SurvivorID" INTO V_SurvivorID FROM "BeanRequests"
    WHERE "BeanRequestID" = P_RequestID LIMIT 1;

    V_ShelterID := GetShelter(V_SurvivorID);

    FOR rec IN
        SELECT "CannedBeanID", "NumberOfCans"
        FROM "BeanRequestItems"  
        WHERE "BeanRequestID" = P_RequestID 
    LOOP
        FOR V_SupplyID IN
            SELECT "BeanSupplyID" FROM "BeanSupplies"
            WHERE "ShelterID" = V_ShelterID
            AND "CannedBeanID" = rec."CannedBeanID"
            AND "ConsumedDate" IS NULL
            LIMIT rec."NumberOfCans"
        LOOP
            CALL UpdateBeanSupply(
                V_SupplyID,
                P_ConsumedDate => CURRENT_DATE
            );
        END LOOP;
    END LOOP;
END;
$$;

COMMIT;

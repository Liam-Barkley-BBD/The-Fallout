CREATE OR REPLACE FUNCTION ValidateRequestItemData()
RETURNS TRIGGER AS $$
DECLARE
    V_SurvivorID INTEGER;
    V_ShelterID INTEGER;
    V_NumBeans INTEGER;
    V_BeanType TEXT;
BEGIN
    IF NOT IdExists(NEW."CannedBeanID", 'CannedBeanID', 'CannedBeans') THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', NEW."CannedBeanID";
    END IF;

    IF NEW."NumberOfCans" <= 0 THEN
      RAISE EXCEPTION 'NumberOfCans has to be a positive integer';
    END IF;

    IF NOT IdExists(NEW."BeanRequestID", 'BeanRequestID', 'BeanRequests') THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist',
        NEW."BeanRequestID";
    END IF;
    
    SELECT "SurvivorID" INTO V_SurvivorID FROM "BeanRequests"
    WHERE "BeanRequestID" = NEW."BeanRequestID";

    IF IsDeceased(V_SurvivorID) THEN
        RAISE EXCEPTION 'Dead people cannot make requests';
    END IF;

    V_ShelterID = GetShelter(V_SurvivorID);

    SELECT COUNT(*)::INTEGER INTO V_NumBeans FROM "BeanSupplies"
    WHERE "ShelterID" = V_ShelterID
    AND "CannedBeanID" = NEW."CannedBeanID"
    AND "ConsumedDate" IS NULL;

    SELECT "BeanType" INTO V_BeanType FROM "CannedBeans"
    WHERE "CannedBeanID" = NEW."CannedBeanID";

    IF (V_NumBeans - NEW."NumberOfCans") < 0 THEN
        RAISE EXCEPTION 'There is not enough stock of % in the shelter''s inventory',
        V_BeanType;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ValidateRequestItem BEFORE INSERT ON "BeanRequestItem"
FOR EACH ROW EXECUTE FUNCTION ValidateRequestItemData();

CREATE OR REPLACE PROCEDURE InsertBeanRequestItem(
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER,
    IN P_BeanRequestID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "BeanRequestItem" ("CannedBeanID", "NumberOfCans", "BeanRequestID")
    VALUES (P_CannedBeanID, P_NumberOfCans, P_BeanRequestID);

    RAISE NOTICE 'Successfully inserted bean request item for request with 
    BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error inserting bean request item: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE InsertBeanRequestItem(
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER,
    IN P_BeanRequestID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "BeanRequestItem" ("CannedBeanID", "NumberOfCans", "BeanRequestID")
    VALUES (P_CannedBeanID, P_NumberOfCans, P_BeanRequestID);

    RAISE NOTICE 'Successfully inserted bean request item for request with 
    BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error inserting bean request item: %', SQLERRM;
END;
$$;

DROP PROCEDURE ApproveBeanRequest;

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
        FROM "BeanRequestItem"
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
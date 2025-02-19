DROP PROCEDURE ApproveBeanRequest;

ALTER TABLE "BeanRequests"
RENAME COLUMN "ApprovalDate" TO "ProcessedDate";

CREATE OR REPLACE FUNCTION ValidateBeanRequestData()
RETURNS TRIGGER AS $$
BEGIN
    IF IsDeceased(NEW."SurvivorID") THEN
        RAISE EXCEPTION 'Dead people can''t make bean requests';
    END IF;

    -- Making sure the request date isn't in the future
    IF NEW."RequestDate" > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestDate cannot be in the future';
    END IF;

    -- If an process date was actually given
    IF NEW."ProcessedDate" IS NOT NULL THEN
        -- Process date cannot be in the future
        IF NEW."ProcessedDate" > CURRENT_DATE THEN
            RAISE EXCEPTION 'ProcessedDate cannot be in the future';
        END IF;

        -- Process date cannot be before the request date. Like ????
        IF NEW."ProcessedDate" < NEW."RequestDate" THEN
            RAISE EXCEPTION
            'A request cannot be processed before it is even issued';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ValidateBeanRequest
BEFORE INSERT OR UPDATE ON "BeanRequests"
FOR EACH ROW EXECUTE FUNCTION ValidateBeanRequestData();

CREATE OR REPLACE PROCEDURE MakeBeanRequest(
    IN P_SurvivorID INTEGER,
    IN P_RequestDate DATE DEFAULT CURRENT_DATE,
    IN P_ProcessDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "BeanRequests" ("SurvivorID", "ProcessedDate", "RequestDate")
    VALUES (P_SurvivorID, P_ProcessDate, P_RequestDate);

    RAISE NOTICE 'Successfully made bean request for survivor with 
    SurvivorID % on %', P_SurvivorID, P_RequestDate;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error making bean request: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE UpdateBeanRequest(
    IN P_BeanRequestID INTEGER,
    IN P_SurvivorID INTEGER DEFAULT NULL,
    IN P_RequestDate DATE DEFAULT NULL,
    IN P_ProcessDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "BeanRequests"
    SET 
        "SurvivorID" = COALESCE(P_SurvivorID, "SurvivorID"),
        "ProcessedDate" = COALESCE(P_ProcessDate, "ProcessedDate"),
        "RequestDate" = COALESCE(P_RequestDate, "RequestDate")
    WHERE "BeanRequestID" = P_BeanRequestID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating bean request: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE ProcessBeanRequest(
    IN P_RequestID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ProcessedFlag DATE;
    V_NumItems INTEGER;
    V_ShelterID INTEGER;
    V_SurvivorID INTEGER;
    V_SupplyID INTEGER;
    rec RECORD;
BEGIN
    IF NOT IdExists(P_RequestID, 'BeanRequestID', 'BeanRequests')
    THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist',
        P_RequestID;
    END IF;

    SELECT "DateProcessed" INTO V_ProcessedFlag FROM "BeanRequests"
    WHERE "BeanRequestID" = P_RequestID;

    IF V_ProcessedFlag IS NOT NULL THEN
        RAISE EXCEPTION 'BeanRequest % has already been processed',
        P_RequestID;
    END IF;

    CALL UpdateBeanRequest(
        P_RequestID,
        P_ProcessDate => CURRENT_DATE
    );

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
CREATE OR REPLACE FUNCTION ValidateBeanRequestData()
RETURNS TRIGGER AS $$
BEGIN
    -- IF NOT IdExists(NEW."SurvivorID", 'SurvivorID', 'Survivors') THEN
    --     RAISE EXCEPTION 'SurvivorID % does not exist', NEW."SurvivorID";
    -- END IF;

    IF IsDeceased(NEW."SurvivorID") THEN
        RAISE EXCEPTION 'Dead people can''t make bean requests';
    END IF;

    -- Making sure the request date isn't in the future
    IF NEW."RequestDate" > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestDate cannot be in the future';
    END IF;

    -- If an approval date was actually given
    IF NEW."ApprovalDate" IS NOT NULL THEN
        -- Approval date cannot be in the future
        IF NEW."ApprovalDate" > CURRENT_DATE THEN
            RAISE EXCEPTION 'ApprovalDate cannot be in the future';
        END IF;

        -- Approval date cannot be before the request date. Like ????
        IF NEW."ApprovalDate" < NEW."RequestDate" THEN
            RAISE EXCEPTION
            'A request cannot be approved before it is even issued';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ValidateBeanRequest BEFORE INSERT OR UPDATE ON "BeanRequests"
FOR EACH ROW EXECUTE FUNCTION ValidateBeanRequestData();

CREATE OR REPLACE PROCEDURE MakeBeanRequest(
    IN P_SurvivorID INTEGER,
    IN P_RequestDate DATE DEFAULT CURRENT_DATE,
    IN P_ApprovalDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "BeanRequests" ("SurvivorID", "ApprovalDate", "RequestDate")
    VALUES (P_SurvivorID, P_ApprovalDate, P_RequestDate);

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
    IN P_ApprovalDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "BeanRequests"
    SET 
        "SurvivorID" = COALESCE(P_SurvivorID, "SurvivorID"),
        "ApprovalDate" = COALESCE(P_ApprovalDate, "ApprovalDate"),
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
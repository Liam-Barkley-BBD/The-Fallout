ALTER TABLE "BeanMissions" DROP COLUMN "ActualEnd";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedStart" TO "StartDate";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedEnd" TO "EndDate";

-- Add missing dates constraints for BeanMissions table
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_StartDateEndDate CHECK ("StartDate" < "EndDate");
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_EndDate CHECK ("EndDate" <= CURRENT_DATE);

/*
    Helper Functions
*/

-- Function to validate a survivor as an active manager in a shelter
CREATE OR REPLACE FUNCTION ValidateSurvivorAsManager(P_SurvivorID INTEGER) RETURNS INTEGER AS $$
DECLARE
    V_ShelterID INTEGER;
BEGIN
    -- Check if survivor exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = P_SurvivorID) THEN
        RAISE EXCEPTION 'SurvivorID % does not exist', P_SurvivorID;
    END IF;

    -- Check if survivor is part of a shelter
    SELECT SS."ShelterID" INTO V_ShelterID
    FROM "ShelterSurvivors" SS
    WHERE SS."SurvivorID" = P_SurvivorID;

    IF V_ShelterID IS NULL THEN
        RAISE EXCEPTION 'SurvivorID % is not part of any shelter', P_SurvivorID;
    END IF;

    -- Check if survivor is a manager
    IF NOT EXISTS (SELECT 1 FROM "Managers" WHERE "SurvivorID" = P_SurvivorID) THEN
        RAISE EXCEPTION 'SurvivorID % is not a manager of ShelterID %', P_SurvivorID, V_ShelterID;
    END IF;

    RETURN V_ShelterID;
END;
$$ LANGUAGE plpgsql;

-- Function to validate a manager for a specific shelter
CREATE OR REPLACE FUNCTION ValidateManagerShelter(P_ManagerShelterID INTEGER, P_OperationShelterID INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    /* Check if the manager is trying to update a mission for another shelter */
    IF P_ManagerShelterID != P_OperationShelterID THEN
        RAISE EXCEPTION 'Manager with ShelterID % cannot perform operation for ShelterID %', P_ManagerShelterID, P_OperationShelterID;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to validate mission dates
CREATE OR REPLACE FUNCTION ValidateMissionDates(P_StartDate DATE, P_EndDate DATE) RETURNS BOOLEAN AS $$
BEGIN
    IF P_EndDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'End date cannot be in the future. Mission needs to be completed before creating mission record.';
    END IF;

    IF P_EndDate < P_StartDate THEN
        RAISE EXCEPTION 'End date cannot be before the start date';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/*
    BeanMissions Procedures
*/

-- CREATE
CREATE OR REPLACE PROCEDURE CreateMission(
    IN P_SurvivorID INTEGER,
    IN P_StartDate DATE,
    IN P_EndDate DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
BEGIN
    /* Validate dates */
    PERFORM ValidateMissionDates(P_StartDate, P_EndDate);

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    -- Insert the new mission
    INSERT INTO "BeanMissions" ("ShelterID", "StartDate", "EndDate")
    VALUES (V_ShelterID, P_StartDate, P_EndDate);
    
    RAISE NOTICE 'Mission created for ShelterID % from % to %', V_ShelterID, P_StartDate, P_EndDate;
END;
$$;

-- READ
CREATE VIEW Missions AS
SELECT * FROM "BeanMissions";

-- UPDATE
CREATE OR REPLACE PROCEDURE UpdateMission(
    IN P_SurvivorID INTEGER,
    IN P_BeanMissionID INTEGER,
    IN P_StartDate DATE,
    IN P_EndDate DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_MissionShelterID INTEGER;
BEGIN

    /* Validate mission update*/
    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'BeanMissionID % does not exist', P_BeanMissionID;
    END IF;

    PERFORM ValidateMissionDates(P_StartDate, P_EndDate);

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    /* Validate operational rights */
    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    PERFORM ValidateManagerShelter(V_ShelterID, V_MissionShelterID);

    -- Update bean mission
    UPDATE "BeanMissions"
    SET 
        "ShelterID" = V_ShelterID,
        "StartDate" = P_StartDate,
        "EndDate"   = P_EndDate
    WHERE "BeanMissionID" = P_BeanMissionID;

    RAISE NOTICE 'Successfully updated BeanMissionID %', P_BeanMissionID;
END;
$$;


-- DELETE
CREATE OR REPLACE PROCEDURE DeleteMission(
    IN P_SurvivorID INTEGER,
    IN P_BeanMissionID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_MissionShelterID INTEGER;
BEGIN
    /* Mission delete validation */
    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'BeanMissionID % does not exist', P_BeanMissionID;
    END IF;

    IF EXISTS (SELECT 1 FROM "MissionYieldItems" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'BeanMissionID % cannot be deleted because it has associated yield items.', P_BeanMissionID;
    END IF;

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    /* Validate operational rights */
    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    PERFORM ValidateManagerShelter(V_ShelterID, V_MissionShelterID)

    -- Delete mission
    DELETE FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    RAISE NOTICE 'MissionID % has been deleted.', P_BeanMissionID;
END;
$$;

/*
MissionYieldItems Procedures
*/

-- CREATE
CREATE OR REPLACE PROCEDURE AddMissionYield(
    IN P_SurvivorID INTEGER,
    IN P_BeanMissionID INTEGER,
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_MissionShelterID INTEGER;
BEGIN

    /* Validate yield */
    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'BeanMissionID % does not exist', P_BeanMissionID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    IF P_NumberOfCans <= 0 THEN
        RAISE EXCEPTION 'Number of cans must be greater than 0';
    END IF;

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    /* Validate operational rights */
    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    PERFORM ValidateManagerShelter(V_ShelterID, V_MissionShelterID);

    INSERT INTO "MissionYieldItems" ("BeanMissionID", "CannedBeanID", "NumberOfCans")
    VALUES (P_BeanMissionID, P_CannedBeanID, P_NumberOfCans);

    RAISE NOTICE 'Added % cans of BeanID % to MissionID %', 
                 P_NumberOfCans, P_CannedBeanID, P_BeanMissionID;
END;
$$;

-- READ
CREATE VIEW TotalMissionYields AS
SELECT 
    M."BeanMissionID", 
    BM."StartDate",
    BM."EndDate",
    SUM(M."NumberOfCans" * C."Grams") AS "TotalYieldGrams"
FROM "MissionYieldItems" M
INNER JOIN "CannedBeans" C ON M."CannedBeanID" = C."CannedBeanID"
INNER JOIN "BeanMissions" BM ON M."BeanMissionID" = BM."BeanMissionID"
GROUP BY M."BeanMissionID", BM."StartDate", BM."EndDate";

CREATE VIEW MissionYields AS
SELECT 
    M."MissionYieldItemID",
    M."BeanMissionID",
    M."NumberOfCans", 
    C."CannedBeanID", 
    C."BeanType", 
    M."NumberOfCans" * C."Grams" || 'g' AS "Yield"
FROM "MissionYieldItems" M
INNER JOIN "CannedBeans" C
ON M."CannedBeanID" = C."CannedBeanID";

-- UPDATE
CREATE OR REPLACE PROCEDURE UpdateMissionYield(
    IN P_SurvivorID INTEGER,
    IN P_MissionYieldItemID INTEGER,
    IN P_BeanMissionID INTEGER,
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_MissionShelterID INTEGER;
BEGIN

    /* Validate yield update */
    IF NOT EXISTS (SELECT 1 FROM "MissionYieldItems" WHERE "MissionYieldItemID" = P_MissionYieldItemID) THEN
        RAISE EXCEPTION 'MissionYieldItemID % does not exist', P_MissionYieldItemID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'BeanMissionID % does not exist', P_BeanMissionID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    IF P_NumberOfCans <= 0 THEN
        RAISE EXCEPTION 'Number of cans must be greater than 0';
    END IF;

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    /* Validate operational rights */
    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    PERFORM ValidateManagerShelter(V_ShelterID, V_MissionShelterID);

    -- Update mission yield
    UPDATE "MissionYieldItems"
    SET 
        "BeanMissionID" = P_BeanMissionID,
        "CannedBeanID" = P_CannedBeanID,
        "NumberOfCans" = P_NumberOfCans
    WHERE "MissionYieldItemID" = P_MissionYieldItemID;

    RAISE NOTICE 'Successfully updated MissionYieldItemID %', P_MissionYieldItemID;
END;
$$;

-- DELETE
CREATE OR REPLACE PROCEDURE DeleteMissionYield(
    IN P_SurvivorID INTEGER,
    IN P_MissionYieldItemID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_MissionShelterID INTEGER;
    V_BeanMissionID INTEGER;
BEGIN

    /* Mission yield delete validation */
    IF NOT EXISTS (SELECT 1 FROM "MissionYieldItems" WHERE "MissionYieldItemID" = P_MissionYieldItemID) THEN
        RAISE EXCEPTION 'MissionYieldItemID % does not exist', P_MissionYieldItemID;
    END IF;

    /* Validate survivor */
    V_ShelterID := ValidateSurvivorAsManager(P_SurvivorID);

    /* Validate operational rights */
    SELECT "BeanMissionID" INTO V_BeanMissionID
    FROM "MissionYieldItems"
    WHERE "MissionYieldItemID" = P_MissionYieldItemID;

    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = V_BeanMissionID;

    PERFORM ValidateManagerShelter(V_ShelterID, V_MissionShelterID);

    -- Delete mission
    DELETE FROM "MissionYieldItems"
    WHERE "MissionYieldItemID" = P_MissionYieldItemID;

    RAISE NOTICE 'MissionYieldItemID % has been deleted.', P_MissionYieldItemID;
END;
$$;

CREATE OR REPLACE FUNCTION PopulateBeanSupplies()
RETURNS TRIGGER AS $$
DECLARE
    V_ShelterID INTEGER;
    i INTEGER;
BEGIN
    -- Get ShelterID for the mission
    SELECT "ShelterID" INTO V_ShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = NEW."BeanMissionID";

    -- Validation
    IF V_ShelterID IS NULL THEN
        RAISE EXCEPTION 'No ShelterID found for BeanMissionID %', NEW."BeanMissionID";
    END IF;

    -- Insert the number of cans into the BeanSupplies table
    FOR i IN 1..NEW."NumberOfCans" LOOP
        INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID")
        VALUES (V_ShelterID, NEW."CannedBeanID");
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Trigger_PopulateBeanSupplies
AFTER INSERT ON "MissionYieldItems"
FOR EACH ROW
EXECUTE FUNCTION PopulateBeanSupplies();
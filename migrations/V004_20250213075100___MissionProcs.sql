-- Add missing dates constraints for BeanMissions table
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_PlannedEnd CHECK ("PlannedEnd" > "PlannedStart");

ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_ActualEnd CHECK ("ActualEnd" > "PlannedStart");

ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_PlannedStart CHECK ("PlannedStart" >= CURRENT_DATE);

-- Procedure to create new missions
CREATE OR REPLACE PROCEDURE InitiateMission(
    IN P_ShelterID INTEGER,
    IN P_PlannedStart DATE,
    IN P_PlannedEnd DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validation
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = P_ShelterID) THEN
        RAISE EXCEPTION 'Shelter ID % does not exist', P_ShelterID;
    END IF;

    IF P_PlannedStart < CURRENT_DATE THEN
        RAISE EXCEPTION 'Planned start date cannot be in the past';
    END IF;

    IF P_PlannedEnd <= P_PlannedStart THEN
        RAISE EXCEPTION 'Planned end date must be after planned start date';
    END IF;

    -- Insert the new mission
    INSERT INTO "BeanMissions" ("ShelterID", "PlannedStart", "PlannedEnd")
    VALUES (P_ShelterID, P_PlannedStart, P_PlannedEnd);
    
    RAISE NOTICE 'Mission initiated for Shelter % from % to %', P_ShelterID, P_PlannedStart, P_PlannedEnd;
END;
$$;

-- Procedure to add mission yields
CREATE OR REPLACE PROCEDURE AddMissionYield(
    IN P_BeanMissionID INTEGER,
    IN P_CannedBeanID INTEGER,
    IN P_NumberOfCans INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
	V_ActualEnd DATE;
BEGIN

    -- Validation
    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'Mission ID % does not exist', P_BeanMissionID;
    END IF;

	SELECT "ActualEnd" INTO V_ActualEnd
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

	IF V_ActualEnd IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot add yield to Mission ID %: Mission ended on %', P_BeanMissionID, V_ActualEnd;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
        RAISE EXCEPTION 'Canned bean type ID % does not exist', P_CannedBeanID;
    END IF;

    IF P_NumberOfCans <= 0 THEN
        RAISE EXCEPTION 'Number of cans must be greater than 0';
    END IF;

    INSERT INTO "MissionYieldItems" ("BeanMissionID", "CannedBeanID", "NumberOfCans")
    VALUES (P_BeanMissionID, P_CannedBeanID, P_NumberOfCans);

    RAISE NOTICE 'Added % cans of Bean ID % to Mission ID', 
                 P_NumberOfCans, P_CannedBeanID;
END;
$$;


-- Procedure to finalize a missions yields
CREATE OR REPLACE PROCEDURE EndMission(
    IN P_BeanMissionID INTEGER,
    IN P_ActualEnd DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_ShelterID INTEGER;
    V_CannedBeanID INTEGER;
    V_NumberOfCans INTEGER;
    V_ActualEnd DATE;
BEGIN
    -- Validation
    IF NOT EXISTS (SELECT 1 FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'Mission ID % does not exist', P_BeanMissionID;
    END IF;

    -- Cannot finalize a mission again
    SELECT "ActualEnd" INTO V_ActualEnd
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    IF NOT V_ActualEnd IS NULL THEN
        RAISE EXCEPTION 'Cannot finalize a mission that has already ended';
    END IF;

    IF P_ActualEnd < (SELECT "PlannedStart" FROM "BeanMissions" WHERE "BeanMissionID" = P_BeanMissionID) THEN
        RAISE EXCEPTION 'Actual End Date cannot be earlier than the Planned Start Date';
    END IF;

    -- Get ShelterID for the mission
    SELECT "ShelterID" INTO V_ShelterID 
    FROM "BeanMissions"
    WHERE "BeanMissionID" = P_BeanMissionID;

    UPDATE "BeanMissions"
    SET "ActualEnd" = P_ActualEnd
    WHERE "BeanMissionID" = P_BeanMissionID;

	-- Add mission yields to supply table
	FOR V_CannedBeanID, V_NumberOfCans IN
	    SELECT "CannedBeanID", "NumberOfCans"
	    FROM "MissionYieldItems"
	    WHERE "BeanMissionID" = P_BeanMissionID
	LOOP
	    FOR i IN 1..V_NumberOfCans LOOP
	        INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID")
	        VALUES (V_ShelterID, V_CannedBeanID);
	    END LOOP;
	END LOOP;

    RAISE NOTICE 'Mission ID % has been finalized with Actual End Date % and supplies updated for Shelter ID %',
                 P_BeanMissionID, P_ActualEnd, V_ShelterID;
END;
$$;



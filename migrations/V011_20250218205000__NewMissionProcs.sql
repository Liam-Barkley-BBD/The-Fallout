
DROP VIEW IF EXISTS Missions;
DROP VIEW IF EXISTS TotalMissionYields;
DROP VIEW IF EXISTS MissionYields;

DROP PROCEDURE IF EXISTS CreateMission;
DROP PROCEDURE IF EXISTS UpdateMission;
DROP PROCEDURE IF EXISTS DeleteMission;
DROP PROCEDURE IF EXISTS AddMissionYield;
DROP PROCEDURE IF EXISTS UpdateMissionYield;
DROP PROCEDURE IF EXISTS DeleteMissionYield;

DROP FUNCTION IF EXISTS ValidateSurvivorAsManager;
DROP FUNCTION IF EXISTS ValidateManagerShelter;
DROP FUNCTION IF EXISTS ValidateMissionDates;

DROP TRIGGER IF EXISTS Trigger_PopulateBeanSupplies ON "MissionYieldItems";
DROP FUNCTION IF EXISTS PopulateBeanSupplies;

ALTER TABLE "MissionYieldItems"
ADD CONSTRAINT CHK_Positive_Cans 
CHECK ("NumberOfCans" > 0);

/* 
    BeanMissions Procedures
*/

-- Proc to create a new mission
CREATE OR REPLACE PROCEDURE CreateMission(
    IN P_ShelterID INTEGER,
    IN P_StartDate DATE,
    IN P_EndDate DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
 
    INSERT INTO "BeanMissions" ("ShelterID", "StartDate", "EndDate")
    VALUES (P_ShelterID, P_StartDate, P_EndDate);
    
    RAISE NOTICE 'Mission created for ShelterID % from % to %', P_ShelterID, P_StartDate, P_EndDate;
END;
$$;

/* 
    MissionYieldItems Triggers 
*/

/* Trigger to add yield to supplies */
CREATE OR REPLACE FUNCTION PopulateBeanSupplies()
RETURNS TRIGGER AS $$
DECLARE
    V_MissionShelterID INTEGER;
    i INTEGER;
BEGIN

    SELECT "ShelterID" INTO V_MissionShelterID
    FROM "BeanMissions"
    WHERE "BeanMissionID" = New."BeanMissionID";

    FOR i IN 1..NEW."NumberOfCans" LOOP
        INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID")
        VALUES (V_MissionShelterID, NEW."CannedBeanID");
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Trigger_PopulateBeanSupplies
AFTER INSERT ON "MissionYieldItems"
FOR EACH ROW
EXECUTE FUNCTION PopulateBeanSupplies();

/*  
    MissionYieldItems Procedures
*/

CREATE OR REPLACE PROCEDURE AddMissionYield(
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

    INSERT INTO "MissionYieldItems" ("BeanMissionID", "CannedBeanID", "NumberOfCans")
    VALUES (P_BeanMissionID, P_CannedBeanID, P_NumberOfCans);

    RAISE NOTICE 'Added % cans of BeanID % to MissionID %', 
                 P_NumberOfCans, P_CannedBeanID, P_BeanMissionID;
END;
$$;

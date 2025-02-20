

ALTER TABLE "BeanMissions" DROP CONSTRAINT CHK_BeanMissions_StartDateEndDate;
ALTER TABLE "BeanMissions" DROP CONSTRAINT CHK_BeanMissions_EndDate; 

ALTER TABLE "BeanMissions" DROP COLUMN "StartDate";
ALTER TABLE "BeanMissions" RENAME COLUMN "EndDate" TO "YieldDate";

ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_EndDate CHECK ("YieldDate" <= CURRENT_DATE);

-- Proc to create a new mission
CREATE OR REPLACE PROCEDURE CreateMission(
    IN P_ShelterID INTEGER,
    IN P_YieldDate DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
 
    INSERT INTO "BeanMissions" ("ShelterID", "YieldDate")
    VALUES (P_ShelterID, P_YieldDate);
    
    RAISE NOTICE 'Mission created for ShelterID % on %', P_ShelterID, P_YieldDate;
END;
$$;
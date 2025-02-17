ALTER TABLE "BeanMissions" DROP COLUMN "ActualEnd";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedStart" TO "StartDate";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedEnd" TO "EndDate";

-- Add missing dates constraints for BeanMissions table
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_StartDateEndDate CHECK ("StartDate" < "EndDate");
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_EndDate CHECK ("EndDate" <= CURRENT_DATE);

ALTER TABLE "Survivors"
DROP COLUMN "PasswordHash";

-- Disable foreign key checks temporarily to avoid constraint issues during bulk insert
SET session_replication_role = 'replica';

-- Insert Managers
-- Ensure we have the required extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Truncate the table before inserting
TRUNCATE TABLE "Managers" RESTART IDENTITY CASCADE;

-- Insert data from CSV using COPY
COPY "Managers"("SurvivorID")
FROM '/data/Managers_data.csv'
WITH CSV HEADER;



-- Insert Survivors
COPY "Survivors"("FirstName", "LastName", "BirthDate")
FROM '/data/Survivors_data.csv' 
DELIMITER ','
CSV HEADER;


-- Insert Shelters
COPY "Shelters"("PopulationCapacity", "SupplyVolume", "Latitude", "Longitude", "EstablishedDate", "DecommisionDate")
FROM '/data/Shelters_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Shelter Survivors 
COPY "ShelterSurvivors"("SurvivorID", "ShelterID")
FROM '/data/ShelterSurvivors_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Bean Supplies
COPY "BeanSupplies"("ShelterID", "CannedBeanID", "ConsumedDate")
FROM '/data/BeanSupplies_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Canned Beans
COPY "CannedBeans"("BeanType", "Grams")
FROM '/data/CannedBeans_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Bean Requests
COPY "BeanRequests"("SurvivorID", "Approved", "RequestTime")
FROM '/data/BeanRequests_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Bean Request Items
COPY "BeanRequestItem"("CannedBeanID", "NumberOfCans", "BeanRequestID")
FROM '/data/BeanRequestItem_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Bean Missions
COPY "BeanMissions"("ShelterID", "StartDate", "EndDate")
FROM '/data/BeanMissions_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Insert Mission Yield Items
COPY "MissionYieldItems"("CannedBeanID", "NumberOfCans", "BeanMissionID")
FROM '/data/MissionYieldItems_data.csv'
DELIMITER ',' 
CSV HEADER;

-- Re-enable foreign key constraints
SET session_replication_role = 'origin';

COMMIT;

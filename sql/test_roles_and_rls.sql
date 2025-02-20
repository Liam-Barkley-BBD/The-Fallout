-- Test Script for Fallout Shelter PostgreSQL RLS

-- 1. Verify ManagerApp Permissions
-- Expected: Can SELECT, INSERT, UPDATE but cannot DELETE. Can only see data related to their ShelterID except for Managers and Survivors tables.
SET ROLE "ManagerApp";
SET app.current_shelter = 24;
SELECT s.*, ss."SurvivorID" FROM "Shelters" s LEFT JOIN "ShelterSurvivors" ss ON s."ShelterID" = ss."ShelterID";
SELECT * FROM "Survivors";
SELECT ss.*, s."ShelterID" FROM "ShelterSurvivors" ss JOIN "Shelters" s ON ss."ShelterID" = s."ShelterID";
SELECT br.*, ss."ShelterID" FROM "BeanRequests" br JOIN "Survivors" sv ON br."SurvivorID" = sv."SurvivorID" JOIN "ShelterSurvivors" ss ON sv."SurvivorID" = ss."SurvivorID";
SELECT bri.*, br."SurvivorID", ss."ShelterID" FROM "BeanRequestItems" bri JOIN "BeanRequests" br ON bri."BeanRequestID" = br."BeanRequestID" JOIN "ShelterSurvivors" ss ON br."SurvivorID" = ss."SurvivorID";
SELECT bm.*, s."ShelterID" FROM "BeanMissions" bm JOIN "Shelters" s ON bm."ShelterID" = s."ShelterID";
SELECT myi.*, bm."ShelterID" FROM "MissionYieldItems" myi JOIN "BeanMissions" bm ON myi."BeanMissionID" = bm."BeanMissionID";
SELECT cb.*, bs."ShelterID" FROM "CannedBeans" cb LEFT JOIN "BeanSupplies" bs ON cb."CannedBeanID" = bs."CannedBeanID";
SELECT bs.*, s."ShelterID" FROM "BeanSupplies" bs JOIN "Shelters" s ON bs."ShelterID" = s."ShelterID";
SELECT bc.*, ss."ShelterID" FROM "BottleCaps" bc JOIN "ShelterSurvivors" ss ON bc."SurvivorID" = ss."SurvivorID";
INSERT INTO "BeanRequests" ("SurvivorID", "RequestDate") VALUES (136, NOW());
UPDATE "Shelters" SET "PopulationCapacity" = 200;
DELETE FROM "BeanRequests" WHERE "BeanRequestID" = 1; -- Should fail
DELETE FROM "BeanRequests"; -- Should fail


-- 2. Verify ReportingApp Permissions
SET ROLE "ReportingApp";
SET app.current_shelter = 2;
SELECT s.*, ss."SurvivorID" FROM "Shelters" s LEFT JOIN "ShelterSurvivors" ss ON s."ShelterID" = ss."ShelterID";
SELECT bm.*, s."ShelterID" FROM "BeanMissions" bm JOIN "Shelters" s ON bm."ShelterID" = s."ShelterID";
SELECT bs.*, s."ShelterID" FROM "BeanSupplies" bs JOIN "Shelters" s ON bs."ShelterID" = s."ShelterID";
SELECT bc.*, ss."ShelterID" FROM "BottleCaps" bc JOIN "ShelterSurvivors" ss ON bc."SurvivorID" = ss."SurvivorID";
INSERT INTO "BeanRequests" ("SurvivorID", "RequestDate") VALUES (136, NOW()); --should fail
UPDATE "Shelters" SET "PopulationCapacity" = 200;--should fail
DELETE FROM "BeanRequests" WHERE "BeanRequestID" = 1; -- Should fail
DELETE FROM "BeanRequests"; -- Should fail


-- 3. Verify SurvivorApp Permissions
SET ROLE "SurvivorApp";
SET app.current_shelter = 24;
select * from "ShelterSurvivors";
SELECT br.*, ss."ShelterID" FROM "BeanRequests" br JOIN "Survivors" sv ON br."SurvivorID" = sv."SurvivorID" JOIN "ShelterSurvivors" ss ON sv."SurvivorID" = ss."SurvivorID";
SELECT bc.*, ss."ShelterID" FROM "BottleCaps" bc JOIN "ShelterSurvivors" ss ON bc."SurvivorID" = ss."SurvivorID";
INSERT INTO "BeanRequests" ("SurvivorID", "RequestDate") VALUES (136, NOW());
UPDATE "BottleCaps" SET "Quantity" = 50;
DELETE FROM "BottleCaps"; -- Should fail

-- 4. Validate that non-permitted actions fail for all roles
SET ROLE "ManagerApp";
SET app.current_shelter = 1;
DELETE FROM "Survivors"; -- Should fail
SET ROLE "ReportingApp";
SET app.current_shelter = 2;
INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID", "ConsumedDate") VALUES (1, 5, NOW()); -- Should fail

-- 5. Check Data Integrity Before & After Modifications
SET ROLE "ManagerApp";
SET app.current_shelter = 1;
SELECT * FROM "Shelters";
UPDATE "Shelters" SET "PopulationCapacity" = 120;
SELECT * FROM "Shelters";

SET app.current_shelter = 2;
SELECT * FROM "Shelters";
UPDATE "Shelters" SET "PopulationCapacity" = 150;
SELECT * FROM "Shelters";

RESET ROLE; -- Reset back to default
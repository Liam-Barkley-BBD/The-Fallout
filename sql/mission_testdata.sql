/*
Note that this is for illustrative purposes only as it depends
on having the same primary keys in the database.
*/

-- InitiateMission(
--     IN P_ShelterID INTEGER,
--     IN P_PlannedStart DATE,
--     IN P_PlannedEnd DATE
-- )

CALL InitiateMission(2, '2025-02-15', '2025-02-20');

-- AddMissionYield(
--     IN P_BeanMissionID INTEGER,
--     IN P_CannedBeanID INTEGER,
--     IN P_NumberOfCans INTEGER
-- )

CALL AddMissionYield(3, 0, 1); 
CALL AddMissionYield(3, 1, -1);
CALL AddMissionYield(3, 1, 1);
CALL AddMissionYield(3, 2, 2);

SELECT M."BeanMissionID", M."NumberOfCans", C."BeanType", M."NumberOfCans" * C."Grams" || 'g' AS "Yield"
FROM "MissionYieldItems" M
INNER JOIN "CannedBeans" C
ON M."CannedBeanID" = C."CannedBeanID";

-- EndMission(
--     IN P_BeanMissionID INTEGER,
--     IN P_ActualEnd DATE
-- )

CALL EndMission(1, '2025-02-19');

SELECT S."ShelterID", C."BeanType"
FROM "BeanSupplies" S
INNER JOIN "CannedBeans" C
ON S."CannedBeanID" = C."CannedBeanID";

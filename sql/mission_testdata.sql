/*
Note that this is for illustrative purposes only as it depends
on having the same primary keys in the database.
*/

-- CreateMission
--     IN P_SurvivorID INTEGER,
--     IN P_StartDate DATE,
--     IN P_EndDate DATE

-- create
CALL CreateMission(2, '2026-02-15', '2026-02-20');
CALL CreateMission(2, '2025-02-15', '2025-02-16');
CALL CreateMission(3, '2025-02-20', '2025-02-16');
CALL CreateMission(3, '2025-02-15', '2025-02-16');

-- update
SELECT * FROM Missions;
CALL UpdateMission(1, 3, '2025-02-14', '2025-02-16');
CALL UpdateMission(1, 1, '2025-02-14', '2025-02-16');
CALL UpdateMission(3, 1, '2026-02-14', '2025-02-16');
CALL UpdateMission(3, 1, '2025-02-14', '2025-02-16');
SELECT * FROM Missions;

-- delete
CALL DeleteMission(1, 1)

-- AddMissionYield
--     IN P_SurvivorID INTEGER,
--     IN P_BeanMissionID INTEGER,
--     IN P_CannedBeanID INTEGER,
--     IN P_NumberOfCans INTEGER

CALL AddMissionYield(1, 1, 0, 1); 
CALL AddMissionYield(1, 3, 0, 1); 
CALL AddMissionYield(1, 1, 1, -1);
CALL AddMissionYield(1, 1, 1, 3);
CALL AddMissionYield(3, 1, 2, 2);

SELECT * FROM MissionYields;
SELECT * FROM TotalMissionYields;

CALL AddMissionYield(3, 1, 1, 1);

SELECT * FROM MissionYields;
SELECT * FROM TotalMissionYields;

/* 
	Updating/Deleting yields should be used with caution since inventory/analytics
	will go out of sync (insert trigger adds yield to inventory).
*/

CALL UpdateMissionYield(3, 1, 1, 2, 1) -- now inventory is out of sync
SELECT * FROM MissionYields;
SELECT * FROM TotalMissionYields;

-- delete mission
CALL DeleteMission(3, 1)

CALL DeleteMissionYield(3, 1)
CALL DeleteMissionYield(3, 2)
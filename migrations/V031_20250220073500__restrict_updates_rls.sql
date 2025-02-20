/*
In tenant application set tenant by using => SET app.current_tenant = <tenant-id>;
In our case, a tenant will be a shelter?
So rather use => SET app.current_shelter = <shelter-id>;
*/

-- DROP PREVIOUS POLICIES

DROP POLICY IF EXISTS ShelterMissionsIsolationPolicy ON "BeanMissions";
DROP POLICY IF EXISTS ShelterMissionYieldIsolationPolicy ON "MissionYieldItems";
DROP POLICY IF EXISTS ShelterBeanSupplyIsolationPolicy ON "BeanSupplies";
DROP POLICY IF EXISTS ShelterResidentsIsolationPolicy ON "ShelterSurvivors";
DROP POLICY IF EXISTS ShelterSurvivorIsolationPolicy ON "Survivors";
DROP POLICY IF EXISTS ShelterBeanRequestsIsolationPolicy ON "BeanRequests";


CREATE OR REPLACE FUNCTION getAppCurrentShelter() RETURNS INTEGER AS $$
DECLARE 
    ShelterId TEXT;
BEGIN
    -- Get the current setting value
    ShelterId := current_setting('app.current_shelter');
    
    -- If it is NULL or empty, raise an exception
    IF ShelterId IS NULL OR ShelterId = '' THEN
        RAISE EXCEPTION 'app.current_shelter is not set. This user needs to set app.current_shelter.';
    END IF;
    
    RETURN ShelterId::INTEGER;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE "BeanMissions"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterMissionsIsolationPolicy ON "BeanMissions";
CREATE POLICY ShelterMissionsIsolationPolicy ON "BeanMissions"
FOR ALL
USING (
  "ShelterID" = getAppCurrentShelter()
)
WITH CHECK (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "MissionYieldItems"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterMissionYieldIsolationPolicy ON "MissionYieldItems";
CREATE POLICY ShelterMissionYieldIsolationPolicy ON "MissionYieldItems"
FOR ALL
USING (
  EXISTS (
        SELECT 1 
        FROM "BeanMissions" bm 
        WHERE bm."BeanMissionID" = "MissionYieldItems"."BeanMissionID"
        AND bm."ShelterID" = getAppCurrentShelter()
    )
)
WITH CHECK (
  EXISTS (
        SELECT 1 
        FROM "BeanMissions" bm 
        WHERE bm."BeanMissionID" = "MissionYieldItems"."BeanMissionID"
        AND bm."ShelterID" = getAppCurrentShelter()
    )
);

ALTER TABLE "BeanSupplies"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterBeanSupplyIsolationPolicy ON "BeanSupplies";
CREATE POLICY ShelterBeanSupplyIsolationPolicy ON "BeanSupplies"
FOR ALL
USING (
  "ShelterID" = getAppCurrentShelter()
)
WITH CHECK (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "ShelterSurvivors"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterResidentsIsolationPolicy ON "ShelterSurvivors";
CREATE POLICY ShelterResidentsIsolationPolicy on "ShelterSurvivors"
FOR ALL
USING (
  "ShelterID" = getAppCurrentShelter()
)
WITH CHECK (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "Survivors"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterSurvivorIsolationPolicy ON "Survivors";
CREATE POLICY ShelterSurvivorIsolationPolicy on "Survivors"
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);

ALTER TABLE "BeanRequests"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterBeanRequestsIsolationPolicy ON "BeanRequests";
CREATE POLICY ShelterBeanRequestsIsolationPolicy on "BeanRequests"
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM "Survivors" s INNER JOIN "ShelterSurvivors" ss ON s."SurvivorID" = ss."SurvivorID"
    WHERE ss."SurvivorID" = "BeanRequests"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "Survivors" s INNER JOIN "ShelterSurvivors" ss ON s."SurvivorID" = ss."SurvivorID"
    WHERE ss."SurvivorID" = "BeanRequests"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);

ALTER TABLE "Shelters"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterIsolationPolicy ON "Shelters";


DROP POLICY IF EXISTS ShelterIsolationPolicy_Select ON "Shelters";
CREATE POLICY ShelterIsolationPolicy_Select ON "Shelters"
FOR SELECT
USING (
  true = true
);

DROP POLICY IF EXISTS ShelterIsolationPolicy_Insert ON "Shelters";
CREATE POLICY ShelterIsolationPolicy_Insert ON "Shelters"
FOR INSERT
WITH CHECK (
  "ShelterID" = getAppCurrentShelter()
);

DROP POLICY IF EXISTS ShelterIsolationPolicy_Delete ON "Shelters";
CREATE POLICY ShelterIsolationPolicy_Delete ON "Shelters"
FOR DELETE
USING (
  "ShelterID" = getAppCurrentShelter()
);

DROP POLICY IF EXISTS ShelterIsolationPolicy_Update ON "Shelters";
CREATE POLICY ShelterIsolationPolicy_Update ON "Shelters"
FOR UPDATE
USING (
  "ShelterID" = getAppCurrentShelter()
)
WITH CHECK (
  "ShelterID" = getAppCurrentShelter()
);;

ALTER TABLE "BeanRequestItems"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterRequestItemsIsolationPolicy ON "BeanRequestItems";
CREATE POLICY ShelterRequestItemsIsolationPolicy ON "BeanRequestItems"
FOR ALL
USING (
  EXISTS (
    SELECT 1 
    FROM "BeanRequestItems" bri 
    INNER JOIN "BeanRequests" br ON br."BeanRequestID" = bri."BeanRequestID" 
    INNER JOIN "Survivors" s ON br."SurvivorID" = s."SurvivorID"
    INNER JOIN "ShelterSurvivors" ss ON ss."SurvivorID" = s."SurvivorID" 
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM "BeanRequestItems" bri 
    INNER JOIN "BeanRequests" br ON br."BeanRequestID" = bri."BeanRequestID" 
    INNER JOIN "Survivors" s ON br."SurvivorID" = s."SurvivorID"
    INNER JOIN "ShelterSurvivors" ss ON ss."SurvivorID" = s."SurvivorID" 
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
);

ALTER TABLE "Managers"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ManagerIsolationPolicy ON "Managers";
DROP POLICY IF EXISTS ManagerIsolationPolicy_Update ON "Managers";
CREATE POLICY ManagerIsolationPolicy_Update ON "Managers"
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM "Managers" m
    INNER JOIN "ShelterSurvivors" ss ON m."SurvivorID" = ss."SurvivorID"
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "Managers" m
    INNER JOIN "ShelterSurvivors" ss ON m."SurvivorID" = ss."SurvivorID"
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
);

DROP POLICY IF EXISTS ManagerIsolationPolicy_Insert ON "Managers";
CREATE POLICY ManagerIsolationPolicy_Insert ON "Managers"
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "Managers" m
    INNER JOIN "ShelterSurvivors" ss ON m."SurvivorID" = ss."SurvivorID"
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
);

DROP POLICY IF EXISTS ManagerIsolationPolicy_Delete ON "Managers";
CREATE POLICY ManagerIsolationPolicy_Delete ON "Managers"
FOR DELETE
USING (
  EXISTS (
    SELECT 1
    FROM "Managers" m
    INNER JOIN "ShelterSurvivors" ss ON m."SurvivorID" = ss."SurvivorID"
    WHERE ss."ShelterID" = getAppCurrentShelter()
  )
);
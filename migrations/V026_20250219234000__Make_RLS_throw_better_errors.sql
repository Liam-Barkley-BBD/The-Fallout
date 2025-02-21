/*
In tenant application set tenant by using => SET app.current_tenant = <tenant-id>;
In our case, a tenant will be a shelter?
So rather use => SET app.current_shelter = <shelter-id>;
*/

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

DROP POLICY IF EXISTS shelter_missions_isolation_policy ON "BeanMissions";
CREATE POLICY ShelterMissionsIsolationPolicy ON "BeanMissions"
USING (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "MissionYieldItems"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shelter_mission_yield_isolation_policy ON "MissionYieldItems";
CREATE POLICY ShelterMissionYieldIsolationPolicy ON "MissionYieldItems"
USING (
  EXISTS (
        SELECT 1 
        FROM "BeanMissions" bm 
        WHERE bm."BeanMissionID" = "MissionYieldItems"."BeanMissionID"
        AND bm."ShelterID" = getAppCurrentShelter()
    )
);

ALTER TABLE "BeanSupplies"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shelter_bean_supply_isolation_policy ON "BeanSupplies";
CREATE POLICY ShelterBeanSupplyIsolationPolicy ON "BeanSupplies"
USING (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "ShelterSurvivors"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shelter_residents_isolation_policy ON "ShelterSurvivors";
CREATE POLICY ShelterResidentsIsolationPolicy on "ShelterSurvivors"
USING (
  "ShelterID" = getAppCurrentShelter()
);

ALTER TABLE "Survivors"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shelter_survivor_isolation_policy ON "Survivors";
CREATE POLICY ShelterSurvivorIsolationPolicy on "Survivors"
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);

ALTER TABLE "BeanRequests"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shelter_bean_requests_isolation_policy ON "BeanRequests";
CREATE POLICY ShelterBeanRequestsIsolationPolicy on "BeanRequests"
USING (
  EXISTS (
    SELECT 1
    FROM "Survivors" s INNER JOIN "ShelterSurvivors" ss ON s."SurvivorID" = ss."SurvivorID"
    WHERE ss."SurvivorID" = "BeanRequests"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);
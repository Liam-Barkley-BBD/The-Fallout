/*
In tenant application set tenant by using => SET app.current_tenant = <tenant-id>;
In our case, a tenant will be a shelter?
So rather use => SET app.current_shelter = <shelter-id>;
*/


ALTER TABLE "BeanMissions"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_missions_isolation_policy ON "BeanMissions"
USING ("ShelterID" = current_setting('app.current_shelter')::INTEGER);

ALTER TABLE "MissionYieldItems"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_mission_yield_isolation_policy ON "MissionYieldItems"
USING (
    EXISTS (
        SELECT 1 
        FROM "BeanMissions" bm 
        WHERE bm."BeanMissionID" = "MissionYieldItems"."BeanMissionID"
        AND bm."ShelterID" = current_setting('app.current_shelter')::INTEGER
    )
);

ALTER TABLE "BeanSupplies"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_bean_supply_isolation_policy ON "BeanSupplies"
USING ("ShelterID" = current_setting('app.current_shelter')::INTEGER);

ALTER TABLE "ShelterSurvivors"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_residents_isolation_policy on "ShelterSurvivors"
USING ("ShelterID" = current_setting('app.current_shelter')::INTEGER);

ALTER TABLE "Survivors"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_survivor_isolation_policy on "Survivors"
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = current_setting('app.current_shelter')::INTEGER
  )
);

ALTER TABLE "BeanRequests"
ENABLE ROW LEVEL SECURITY;

CREATE POLICY shelter_bean_requests_isolation_policy on "BeanRequests"
USING (
  EXISTS (
    SELECT 1
    FROM "Survivors" s INNER JOIN "ShelterSurvivors" ss ON s."SurvivorID" = ss."SurvivorID"
    WHERE ss."SurvivorID" = "BeanRequests"."SurvivorID"
    AND ss."ShelterID" = current_setting('app.current_shelter')::INTEGER
  )
);
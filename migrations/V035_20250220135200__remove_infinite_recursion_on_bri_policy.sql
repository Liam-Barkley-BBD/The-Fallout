ALTER TABLE "BeanRequestItems"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterRequestItemsIsolationPolicy ON "BeanRequestItems";
CREATE POLICY ShelterRequestItemsIsolationPolicy ON "BeanRequestItems"
FOR ALL
USING (
  EXISTS (
    SELECT 1 
    FROM "BeanRequests" br
    INNER JOIN "Survivors" s ON br."SurvivorID" = s."SurvivorID"
    INNER JOIN "ShelterSurvivors" ss ON ss."SurvivorID" = s."SurvivorID" 
    WHERE ss."ShelterID" = getAppCurrentShelter()
      AND br."BeanRequestID" = "BeanRequestItems"."BeanRequestID"
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM "BeanRequests" br
    INNER JOIN "Survivors" s ON br."SurvivorID" = s."SurvivorID"
    INNER JOIN "ShelterSurvivors" ss ON ss."SurvivorID" = s."SurvivorID" 
    WHERE ss."ShelterID" = getAppCurrentShelter()
      AND br."BeanRequestID" = "BeanRequestItems"."BeanRequestID"
  )
);

ALTER TABLE "Managers"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ManagerIsolationPolicy ON "Managers";
DROP POLICY IF EXISTS ManagerIsolationPolicy_Insert ON "Managers";
DROP POLICY IF EXISTS ManagerIsolationPolicy_Update ON "Managers";
DROP POLICY IF EXISTS ManagerIsolationPolicy_Delete ON "Managers";

DROP POLICY IF EXISTS ManagerIsolationPolicy ON "Managers";
CREATE POLICY ManagerIsolationPolicy ON "Managers"
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."ShelterID" = getAppCurrentShelter()
    AND "Managers"."SurvivorID" = ss."SurvivorID"
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."ShelterID" = getAppCurrentShelter()
    AND "Managers"."SurvivorID" = ss."SurvivorID"
  )
);
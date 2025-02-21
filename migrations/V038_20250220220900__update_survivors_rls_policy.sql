ALTER TABLE "Survivors"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ShelterSurvivorIsolationPolicy ON "Survivors";

CREATE POLICY ShelterSurvivorIsolationPolicy_Select on "Survivors"
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);

CREATE POLICY ShelterSurvivorIsolationPolicy_Update on "Survivors"
FOR Update
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

CREATE POLICY ShelterSurvivorIsolationPolicy_Delete on "Survivors"
FOR Delete
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."SurvivorID" = "Survivors"."SurvivorID"
    AND ss."ShelterID" = getAppCurrentShelter()
  )
);

CREATE POLICY ShelterSurvivorIsolationPolicy_Insert on "Survivors"
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
  )
);

ALTER TABLE "BottleCaps"
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS BottleCapsIsolationPolicy on "BottleCaps";
CREATE POLICY BottleCapsIsolationPolicy on "BottleCaps"
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."ShelterID" = getAppCurrentShelter()
    AND "BottleCaps"."SurvivorID" = ss."SurvivorID"
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "ShelterSurvivors" ss
    WHERE ss."ShelterID" = getAppCurrentShelter()
    AND "BottleCaps"."SurvivorID" = ss."SurvivorID"
  )
);
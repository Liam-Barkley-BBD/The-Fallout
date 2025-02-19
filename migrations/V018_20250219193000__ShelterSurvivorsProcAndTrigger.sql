ALTER TABLE "Shelters"
RENAME COLUMN "DecommisionDate" TO "DecommissionDate";

CREATE OR REPLACE FUNCTION CheckPopulationCapacity() 
RETURNS TRIGGER AS $$
DECLARE
    v_population_capacity INTEGER;
    v_current_population INTEGER;
BEGIN
    -- Get the PopulationCapacity of the shelter
    SELECT "PopulationCapacity" INTO v_population_capacity FROM "Shelters" WHERE "ShelterID" = NEW."ShelterID";

    -- Count current population in the shelter
    SELECT COUNT(*) INTO v_current_population
    FROM "ShelterSurvivors"
    WHERE "ShelterID" = NEW."ShelterID";

    -- If the population exceeds capacity, raise an exception
    IF v_current_population >= v_population_capacity THEN
        RAISE EXCEPTION 'Shelter with ID % has reached its population capacity.', NEW."ShelterID";
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to fire before inserting a new survivor into ShelterSurvivors
CREATE TRIGGER CheckPopulationCapacityTrigger
BEFORE INSERT ON "ShelterSurvivors"
FOR EACH ROW
EXECUTE FUNCTION CheckPopulationCapacity();


CREATE OR REPLACE PROCEDURE AddSurvivorToShelter(
    IN survivor_id INTEGER, 
    IN shelter_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the Survivor exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = survivor_id) THEN
        RAISE EXCEPTION 'Survivor with ID % does not exist.', survivor_id;
    END IF;

    -- Check if the Shelter exists
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = shelter_id) THEN
        RAISE EXCEPTION 'Shelter with ID % does not exist.', shelter_id;
    END IF;

    -- Check if the Shelter is decommissioned (DecommissionDate is not NULL)
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = shelter_id AND "DecommissionDate" IS NOT NULL) THEN
        RAISE EXCEPTION 'Cannot add survivor to decommissioned shelter with ID %.', shelter_id;
    END IF;

    -- Check if the Survivor is already assigned to the Shelter
    IF EXISTS (SELECT 1 FROM "ShelterSurvivors" WHERE "SurvivorID" = survivor_id AND "ShelterID" = shelter_id) THEN
        RAISE EXCEPTION 'Survivor with ID % is already assigned to Shelter %.', survivor_id, shelter_id;
    END IF;

    -- Add the Survivor to the Shelter 
    INSERT INTO "ShelterSurvivors"("SurvivorID", "ShelterID") 
    VALUES (survivor_id, shelter_id);

    RAISE NOTICE 'Survivor % added to Shelter % successfully.', survivor_id, shelter_id;
END;
$$;




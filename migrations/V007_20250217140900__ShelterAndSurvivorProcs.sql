ALTER TABLE "Survivors"
ADD COLUMN "DeceasedDate" DATE;

ALTER TABLE "ShelterSurvivors" RENAME COLUMN "ShelterSurvivors" TO "ShelterSurvivorID";

CREATE OR REPLACE FUNCTION RemoveSurvivorFromShelter()
RETURNS TRIGGER AS $$
BEGIN
    -- Remove survivor from ShelterSurvivors table if they exist there
    DELETE FROM "ShelterSurvivors"
    WHERE "SurvivorID" = OLD."SurvivorID";

    RAISE NOTICE 'Survivor % removed from any shelter assignments.', OLD."SurvivorID";

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

--Trigger to Remove Deceased Survivors from ShelterSurvivors
CREATE TRIGGER trg_RemoveSurvivorFromShelter
AFTER UPDATE OF "DeceasedDate" ON "Survivors"
FOR EACH ROW
WHEN (NEW."DeceasedDate" IS NOT NULL)
EXECUTE FUNCTION RemoveSurvivorFromShelter();

CREATE TRIGGER trg_DeleteSurvivorFromShelter
AFTER DELETE ON "Survivors"
FOR EACH ROW
EXECUTE FUNCTION RemoveSurvivorFromShelter();


CREATE OR REPLACE PROCEDURE UpdateDeceased(IN survivor_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the Survivor exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = survivor_id) THEN
        RAISE EXCEPTION 'Survivor with ID % does not exist.', survivor_id;
    END IF;

    -- Update "Survivors" DeceasedDate
    UPDATE "Survivors" SET "DeceasedDate" = CURRENT_DATE WHERE "SurvivorID" = survivor_id;

    RAISE NOTICE 'Survivor % has been updated successfully.', survivor_id;
END;
$$;


CREATE OR REPLACE PROCEDURE AddSurvivors(IN first_name VARCHAR(128), IN last_name VARCHAR(128), IN birth_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Ensure all required fields are provided
    IF first_name IS NULL OR last_name IS NULL OR birth_date IS NULL THEN
        RAISE EXCEPTION 'FirstName, LastName, and BirthDate are required fields.';
    END IF;

    -- Check if the survivor already exists based on their name (you can adjust this logic)
    IF EXISTS (SELECT 1 FROM "Survivors" WHERE "FirstName" = first_name AND "LastName" = last_name) THEN
        RAISE EXCEPTION 'Survivor with name % % already exists.', first_name, last_name;
    END IF;

    -- Insert new survivor
    INSERT INTO "Survivors" ("FirstName", "LastName", "BirthDate")
    VALUES (first_name, last_name, birth_date);

    RAISE NOTICE 'Survivor % % added successfully.', first_name, last_name;
END;
$$;


CREATE OR REPLACE PROCEDURE DecommissionShelter(IN shelter_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the shelter exists
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = shelter_id) THEN
        RAISE EXCEPTION 'Shelter with ID % does not exist.', shelter_id;
    END IF;

    -- Check if there are survivors assigned to this shelter
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = shelter_id AND "SurvivorID" IS NOT NULL) THEN
        RAISE EXCEPTION 'Shelter % has survivors assigned. Remove them before decommissioning.', shelter_id;
    END IF;

    -- Decommission the shelter (update status or delete based on your requirement)
    UPDATE "Shelters" SET "DecommisionDate" = CURRENT_DATE WHERE "ShelterID" = shelter_id;

    RAISE NOTICE 'Shelter % has been decommissioned successfully.', shelter_id;
END;
$$;


CREATE OR REPLACE PROCEDURE AddSurvivorToShelter(IN survivor_id INTEGER, IN shelter_id INTEGER)
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

    -- Check if the Survivor is already assigned to the Shelter
    IF EXISTS (SELECT 1 FROM "ShelterSurvivors" WHERE "SurvivorID" = survivor_id AND "ShelterID" = shelter_id) THEN
        RAISE EXCEPTION 'Survivor with ID % is already assigned to Shelter %.', survivor_id, shelter_id;
    END IF;

    -- Add the Survivor to the Shelter 
    INSERT INTO "ShelterSurvivors"("SurvivorID", "ShelterID") VALUES 
    (survivor_id, shelter_id);

    RAISE NOTICE 'Survivor % added to Shelter % successfully.', survivor_id, shelter_id;
END;
$$;

CREATE OR REPLACE PROCEDURE RemoveSurvivors(IN survivor_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the Survivor exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = survivor_id) THEN
        RAISE EXCEPTION 'Survivor with ID % does not exist.', survivor_id;
    END IF;

    -- Optional: Check if the Survivor is assigned to any shelter
    -- Assuming you have a "Shelter" table or relationship to check if the survivor is still in a shelter
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "SurvivorID" = survivor_id) THEN
        RAISE EXCEPTION 'Survivor % is currently assigned to a shelter. Remove them first.', survivor_id;
    END IF;

    -- Remove the survivor from the database
    DELETE FROM "Survivors" WHERE "SurvivorID" = survivor_id;

    RAISE NOTICE 'Survivor % has been removed successfully.', survivor_id;
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
    UPDATE "Shelters" SET "Status" = 'Decommissioned' WHERE "ShelterID" = shelter_id;

    RAISE NOTICE 'Shelter % has been decommissioned successfully.', shelter_id;
END;
$$;

CREATE OR REPLACE FUNCTION remove_survivor_from_shelter()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove survivor from the shelter when they are deleted from the Survivors table
    DELETE FROM "Shelters"
    WHERE "SurvivorID" = OLD."SurvivorID";
    
    RAISE NOTICE 'Survivor % removed from any shelter assignments.', OLD."SurvivorID";

    -- Return the old row (required for DELETE trigger functions)
    RETURN OLD;
END;
$$;

--Trigger to remove survivors from Shelter when removing from Survivors 
CREATE TRIGGER trg_remove_survivor_from_shelter
AFTER DELETE ON "Survivors"
FOR EACH ROW
EXECUTE FUNCTION remove_survivor_from_shelter();

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
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "SurvivorID" = survivor_id AND "ShelterID" = shelter_id) THEN
        RAISE EXCEPTION 'Survivor with ID % is already assigned to Shelter %.', survivor_id, shelter_id;
    END IF;

    -- Add the Survivor to the Shelter (assuming there's a SurvivorID field in the Shelters table)
    UPDATE "Shelters"
    SET "SurvivorID" = survivor_id
    WHERE "ShelterID" = shelter_id;

    RAISE NOTICE 'Survivor % added to Shelter % successfully.', survivor_id, shelter_id;
END;
$$;

CREATE OR REPLACE PROCEDURE TransferSurvivor(
    IN survivor_id INTEGER,
    IN source_shelter_id INTEGER,
    IN destination_shelter_id INTEGER
)
LANGUAGE plpgsql
AS $$ 
BEGIN
    -- Check if the Survivor exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = survivor_id) THEN
        RAISE EXCEPTION 'Survivor with ID % does not exist.', survivor_id;
    END IF;

    -- Check if the Source Shelter exists
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = source_shelter_id) THEN
        RAISE EXCEPTION 'Source Shelter with ID % does not exist.', source_shelter_id;
    END IF;

    -- Check if the Destination Shelter exists
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = destination_shelter_id) THEN
        RAISE EXCEPTION 'Destination Shelter with ID % does not exist.', destination_shelter_id;
    END IF;

    -- Check if the Survivor is assigned to the Source Shelter
    IF NOT EXISTS (SELECT 1 FROM "ShelterSurvivors" WHERE "SurvivorID" = survivor_id AND "ShelterID" = source_shelter_id) THEN
        RAISE EXCEPTION 'Survivor with ID % is not assigned to Source Shelter %.', survivor_id, source_shelter_id;
    END IF;

    -- Check if the Survivor is already assigned to the Destination Shelter
    IF EXISTS (SELECT 1 FROM "ShelterSurvivors" WHERE "SurvivorID" = survivor_id AND "ShelterID" = destination_shelter_id) THEN
        RAISE EXCEPTION 'Survivor with ID % is already assigned to Destination Shelter %.', survivor_id, destination_shelter_id;
    END IF;

    -- Check if the Source Shelter is decommissioned
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = source_shelter_id AND "DecommissionDate" IS NOT NULL) THEN
        RAISE EXCEPTION 'Source Shelter with ID % is decommissioned and cannot transfer survivors.', source_shelter_id;
    END IF;

    -- Check if the Destination Shelter is decommissioned
    IF EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = destination_shelter_id AND "DecommissionDate" IS NOT NULL) THEN
        RAISE EXCEPTION 'Destination Shelter with ID % is decommissioned and cannot accept survivors.', destination_shelter_id;
    END IF;

    -- Remove the Survivor from the Source Shelter
    DELETE FROM "ShelterSurvivors"
    WHERE "SurvivorID" = survivor_id AND "ShelterID" = source_shelter_id;

    -- Add the Survivor to the Destination Shelter
    INSERT INTO "ShelterSurvivors" ("SurvivorID", "ShelterID")
    VALUES (survivor_id, destination_shelter_id);

    -- No COMMIT here, let the caller handle it

    RAISE NOTICE 'Survivor % successfully transferred from Shelter % to Shelter %.', survivor_id, source_shelter_id, destination_shelter_id;

EXCEPTION
    WHEN OTHERS THEN
        -- No ROLLBACK here either
        RAISE EXCEPTION 'Error transferring survivor %: %', survivor_id, SQLERRM;
END;
$$;

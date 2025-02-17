/*

  ____                    _____                   _ _           
 |  _ \                  / ____|                 | (_)          
 | |_) | ___  __ _ _ __ | (___  _   _ _ __  _ __ | |_  ___  ___ 
 |  _ < / _ \/ _` | '_ \ \___ \| | | | '_ \| '_ \| | |/ _ \/ __|
 | |_) |  __/ (_| | | | |____) | |_| | |_) | |_) | | |  __/\__ \
 |____/ \___|\__,_|_| |_|_____/ \__,_| .__/| .__/|_|_|\___||___/
                                     | |   | |                  
                                     |_|   |_|                  
*/

-- Adding the necessary constraints

ALTER TABLE "BeanSupplies"
ADD CONSTRAINT CHK_SID_NN CHECK ("ShelterID" IS NOT NULL),
ADD CONSTRAINT CHK_CBID_NN CHECK ("CannedBeanID" IS NOT NULL),
ADD CONSTRAINT CHK_CD_NFuture CHECK ("ConsumedDate" IS NULL OR "ConsumedDate" <= CURRENT_DATE);

-- Insert Procedure
CREATE OR REPLACE PROCEDURE InsertBeanSupply(
    IN P_ShelterID INTEGER,
    IN P_CannedBeanID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if the ShelterID exists
    IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = P_ShelterID) THEN
        RAISE EXCEPTION 'ShelterID % does not exist', P_ShelterID;
    END IF;
    
    -- Checking if CannedBeanID exists
    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    -- Inserting the record
    INSERT INTO "BeanSupplies" ("ShelterID", "CannedBeanID")
    VALUES (P_ShelterID, P_CannedBeanID);

    -- Success!
    RAISE NOTICE 'Successfully inserted into BeanSupplies';

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            RAISE EXCEPTION 'Error inserting into "BeanSupplies": %', SQLERRM;
END;
$$;

-- Update Procedure
CREATE OR REPLACE PROCEDURE UpdateBeanSupply(
    P_BeanSupplyID INTEGER,
    P_ShelterID INTEGER DEFAULT NULL,
    P_CannedBeanID INTEGER DEFAULT NULL,
    P_ConsumedDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if BeanSupplyID exists
    IF NOT EXISTS (SELECT 1 FROM "BeanSupplies" WHERE "BeanSupplyID" = P_BeanSupplyID) THEN
        RAISE EXCEPTION 'BeanSupplyID % does not exist', P_BeanSupplyID;
    END IF;

    -- Checking if ShelterID exists
    IF P_ShelterID IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM "Shelters" WHERE "ShelterID" = P_ShelterID) THEN
            RAISE EXCEPTION 'ShelterID % does not exist', P_ShelterID;
        END IF;
    END IF;

    -- Checking if CannedBeanID exists
    IF P_CannedBeanID IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
            RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
        END IF;
    END IF;

    -- Checking if ConsumedDate is not in the future
    IF P_ConsumedDate IS NOT NULL AND P_ConsumedDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'ConsumedDate cannot be in the future';
    END IF;

    -- Updating the record
    UPDATE "BeanSupplies"
    SET "ShelterID" = COALESCE(P_ShelterID, "ShelterID"),
        "CannedBeanID" = COALESCE(P_CannedBeanID, "CannedBeanID"),
        "ConsumedDate" = COALESCE(P_ConsumedDate, "ConsumedDate")
    WHERE "BeanSupplyID" = P_BeanSupplyID;

    -- Success!
    RAISE NOTICE 'Successfully updated record with BeanSupplieID %', P_BeanSupplyID;

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            RAISE EXCEPTION 'Error updating into "BeanSupplies": %', SQLERRM;
END;
$$;

-- Consume Procedure
CREATE OR REPLACE PROCEDURE ConsumeBeanSupply(
    p_BeanSupplyID INTEGER,
    p_ConsumedDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- If no date is provided, use the current date
    IF p_ConsumedDate IS NULL THEN
        p_ConsumedDate := CURRENT_DATE;
    END IF;

    -- ConsumedDate can't be in the future bro
    IF p_ConsumedDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'ConsumedDate cannot be in the future';
    END IF;

    -- Calling update procedure to set ConsumedDate
    CALL UpdateBeanSupply(
        p_BeanSupplyID,
        P_ConsumedDate => p_ConsumedDate
    );
END;
$$;

-- Deleting a record in BeanSupplies

CREATE OR REPLACE PROCEDURE DeleteBeanSupply(
    IN P_BeanSupplyID INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if the BeanRequestID exists
    IF NOT EXISTS (SELECT 1 FROM "BeanSupplies" WHERE "BeanSupplyID" = P_BeanSupplyID) THEN
        RAISE EXCEPTION 'BeanSupplyID % does not exist', P_BeanSupplyID;
    END IF;

    -- Get outta here (Deleting the BeanSupplies)
    DELETE FROM "BeanSupplies"
    WHERE "BeanSupplyID" = P_BeanSupplyID;

    -- Success! :)
    RAISE NOTICE 'Successfully deleted BeanSupplyID %', P_BeanSupplyID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error deleting bean supply: %', SQLERRM;
END;
$$;

/*
BeanSupplies Views
*/

-- View to count different canned beans per shelter
CREATE OR REPLACE VIEW ShelterBeanTypeCount AS
SELECT 
    "ShelterID", 
    COUNT(DISTINCT "CannedBeanID") AS BeanCount
FROM "BeanSupplies"
GROUP BY "ShelterID";

-- View to count the number of each specific canned bean type per shelter
CREATE OR REPLACE VIEW ShelterBeanInventory AS
SELECT 
    bs."ShelterID", 
    cb."BeanType", 
    COUNT(bs."CannedBeanID") AS BeanCount
FROM "BeanSupplies" bs
JOIN "CannedBeans" cb ON bs."CannedBeanID" = cb."CannedBeanID"
GROUP BY bs."ShelterID", cb."BeanType";

-- View to count the total number of beans per shelter
CREATE OR REPLACE VIEW ShelterTotalBeans AS
SELECT 
    "ShelterID", 
    COUNT("CannedBeanID") AS TotalBeans
FROM "BeanSupplies"
GROUP BY "ShelterID";
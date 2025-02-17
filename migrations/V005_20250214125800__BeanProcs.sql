/*
   _____                           _ ____                       
  / ____|                         | |  _ \                      
 | |     __ _ _ __  _ __   ___  __| | |_) | ___  __ _ _ __  ___ 
 | |    / _` | '_ \| '_ \ / _ \/ _` |  _ < / _ \/ _` | '_ \/ __|
 | |___| (_| | | | | | | |  __/ (_| | |_) |  __/ (_| | | | \__ \
  \_____\__,_|_| |_|_| |_|\___|\__,_|____/ \___|\__,_|_| |_|___/
*/

/*
Adding Constraints
*/

ALTER TABLE "CannedBeans"
ADD CONSTRAINT CHK_Grams CHECK ("Grams" >= 0);

/*
Checks that 'BeanType' is a non-empty string that only contains alphabetic 
characters
*/
ALTER TABLE "CannedBeans"
ADD CONSTRAINT CHK_BeanType
CHECK ("BeanType" ~ '^[A-Za-z ]+$' AND "BeanType" <> '');

/*
CannedBeans Procedures
*/

-- Inserting into CannedBeans

CREATE OR REPLACE PROCEDURE InsertCannedBean(
    IN P_BeanType VARCHAR(128),
    IN P_Grams FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Inserting into CannedBeans Table
    INSERT INTO "CannedBeans" ("BeanType", "Grams")
    VALUES (P_BeanType, P_Grams);

    -- Success!
    RAISE NOTICE 'Successfully inserted % (% grams)', P_BeanType, P_Grams;

    EXCEPTION
        WHEN others THEN
            -- Not success! :(
            RAISE EXCEPTION 'Error inserting into "CannedBeans": %', SQLERRM;
END;
$$;

-- Updating a record in CannedBeans

CREATE OR REPLACE PROCEDURE UpdateCannedBean(
    IN P_CannedBeanID INTEGER,
    IN P_BeanType VARCHAR(128),
    IN P_Grams FLOAT
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Exists INTEGER;
BEGIN
    -- Check if the record exists
    SELECT COUNT(*) INTO V_Exists FROM "CannedBeans"
    WHERE "CannedBeanID" = P_CannedBeanID;

    IF V_Exists = 0 THEN -- No records with that CannedBeanID was found
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    -- Performing the update
    UPDATE "CannedBeans"
    SET
        "BeanType" = P_BeanType,
        "Grams" = P_Grams
    WHERE "CannedBeanID" = P_CannedBeanID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated CannedBeanID %: % (% grams)',
        P_CannedBeanID, P_BeanType, P_Grams;
    
    EXCEPTION
        WHEN others THEN
            -- Not success! :( Something went wrong
            RAISE EXCEPTION 'Error updating canned bean %: %',
                P_CannedBeanID, SQLERRM;
END;
$$;

-- Deleting a record in CannedBeans 

CREATE OR REPLACE PROCEDURE DeleteCannedBean(
    IN P_CannedBeanID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Exists INTEGER;
BEGIN
    SELECT COUNT(*) INTO V_Exists FROM "CannedBeans"
    WHERE "CannedBeanID" = P_CannedBeanID;

    If V_Exists = 0 THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    -- Get outta here (Performing the delete)
    DELETE FROM "CannedBeans"
    WHERE "CannedBeanID" = P_CannedBeanID;

    RAISE NOTICE 'Successfully deleted record with CannedBean ID: %',
        P_CannedBeanID;
    
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error deleting canned bean: %', SQLERRM;
END;
$$;

/*
  ____                   _____                            _       
 |  _ \                 |  __ \                          | |      
 | |_) | ___  __ _ _ __ | |__) |___  __ _ _   _  ___  ___| |_ ___ 
 |  _ < / _ \/ _` | '_ \|  _  // _ \/ _` | | | |/ _ \/ __| __/ __|
 | |_) |  __/ (_| | | | | | \ \  __/ (_| | |_| |  __/\__ \ |_\__ \
 |____/ \___|\__,_|_| |_|_|  \_\___|\__, |\__,_|\___||___/\__|___/
                                       | |                        
                                       |_|                        
*/

/*
Adding Constraints
*/

ALTER TABLE "BeanRequests"
    ALTER COLUMN "RequestTime" SET DEFAULT CURRENT_DATE,
    ALTER COLUMN "Approved" SET DEFAULT FALSE,
    ALTER COLUMN "SurvivorID" SET NOT NULL;

ALTER TABLE "BeanRequests"
ADD CONSTRAINT CHK_RequestTime CHECk ("RequestTime" <= CURRENT_DATE);


/*
BeanRequests Procedures
*/

-- Inserting into BeanRequests

CREATE OR REPLACE PROCEDURE InsertBeanRequest(
    IN P_SurvivorID INTEGER,
    IN P_Approved BOOLEAN DEFAULT FALSE,
    IN P_RequestTime DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Exists INTEGER;
BEGIN
    -- Checking if the SurvivorID exists
    SELECT COUNT(*) INTO V_Exists FROM "Survivors"
    WHERE "SurvivorID" = P_SurvivorID;

    IF V_Exists = 0 THEN
        RAISE EXCEPTION 'SurvivorID % does not exist', P_SurvivorID;
    END IF;

    IF P_RequestTime > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestTime cannot be in the future';
    END IF;

    INSERT INTO "BeanRequests" ("SurvivorID", "Approved", "RequestTime")
    VALUES (P_SurvivorID, P_Approved, P_RequestTime);

    RAISE NOTICE 'Successfully inserted bean request for survivor with 
    SurvivorID % on %', P_SurvivorID, P_RequestTime;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error inserting bean request: %', SQLERRM;
END;
$$;

-- Updating a record in BeanRequests

CREATE OR REPLACE PROCEDURE UpdateBeanRequest(
    IN P_BeanRequestID INTEGER,
    IN P_SurvivorID INTEGER DEFAULT NULL,
    IN P_Approved BOOLEAN DEFAULT NULL,
    IN P_RequestTime DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Exists INTEGER;
    V_Survivor_Exists INTEGER;
BEGIN
    -- Checking if the BeanRequestID exists
    SELECT COUNT(*) INTO V_Exists FROM "BeanRequests"
    WHERE "BeanRequestID" = P_BeanRequestID;

    IF V_Exists = 0 THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    END IF;

    -- If SurvivorID is provided, check if it exists
    IF P_SurvivorID IS NOT NULL THEN
        SELECT COUNT(*) INTO V_Survivor_Exists FROM "Survivors" WHERE "SurvivorID" = p_SurvivorID;

        IF V_Survivor_Exists = 0 THEN
            RAISE EXCEPTION 'SurvivorID % does not exist', P_SurvivorID;
        END IF;
    END IF;

    -- Ensuring RequestTime is not in the future
    IF P_RequestTime IS NOT NULL AND P_RequestTime > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestTime cannot be in the future';
    END IF;

    -- Finally perform the BeanRequestUpdate
    UPDATE "BeanRequests"
    SET 
        "SurvivorID" = COALESCE(P_SurvivorID, "SurvivorID"),
        "Approved" = COALESCE(P_Approved, "Approved"),
        "RequestTime" = COALESCE(P_RequestTime, "RequestTime")
    WHERE "BeanRequestID" = P_BeanRequestID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated BeanRequestID %', p_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error updating bean request: %', SQLERRM;
END;
$$;

-- Deleting a record in BeanRequests

CREATE OR REPLACE PROCEDURE DeleteBeanRequest(
    IN P_BeanRequestID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Exists INTEGER;
BEGIN
    -- Checking if the BeanRequestID exists
    SELECT COUNT(*) INTO V_Exists FROM "BeanRequests" WHERE "BeanRequestID" = P_BeanRequestID;
    
    IF V_Exists = 0 THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    END IF;

    -- Get outta here (Deleting the BeanRequest)
    DELETE FROM "BeanRequests"
    WHERE "BeanRequestID" = P_BeanRequestID;

    -- Success! :)
    RAISE NOTICE 'Successfully deleted BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error deleting bean request: %', SQLERRM;
END;
$$;

-- Approving a BeanRequest

CREATE OR REPLACE PROCEDURE ApproveBeanRequest(
    IN P_BeanRequestID INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- V_Exists INTEGER;
    V_AlreadyApproved BOOLEAN;
BEGIN
    -- Checking if the BeanRequestID exists
    -- SELECT COUNT(*) INTO V_Exists FROM "BeanRequests" WHERE "BeanRequestID" = P_BeanRequestID;
    
    -- IF V_Exists = 0 THEN
    --     RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    -- END IF;

    SELECT "Approved" INTO V_AlreadyApproved FROM "BeanRequests"
    WHERE "BeanRequestID" = P_BeanRequestID;

    IF V_AlreadyApproved IS NULL THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    END IF;

    -- If already approved, then what are you approving for?? Raise an error!
    IF V_AlreadyApproved THEN
        RAISE EXCEPTION 'BeanRequestID % is already approved.', p_BeanRequestID;
    END IF;

    -- Calling the UpdateBeanRequest procedure to approve the request
    CALL UpdateBeanRequest(P_BeanRequestID, NULL, TRUE, NULL);

    -- Success! :)
    RAISE NOTICE 'Successfully approved BeanRequestID %', P_BeanRequestID;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error approving bean request: %', SQLERRM;
END;
$$;

/*
BeanRequests Views
*/

CREATE VIEW ApprovedBeanRequests AS
SELECT
    "BeanRequestID",
    "SurvivorID",
    "RequestTime"
FROM "BeanRequests"
WHERE "Approved" = TRUE;

CREATE VIEW SurvivorRequestCounts AS
SELECT
    "SurvivorID",
    COUNT("BeanRequestID") AS "TotalRequests"
FROM "BeanRequests"
GROUP BY "SurvivorID";
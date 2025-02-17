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

-- ALTER TABLE "CannedBeans"
-- ADD CONSTRAINT CHK_Grams CHECK ("Grams" >= 0);

-- /*
-- Checks that 'BeanType' is a non-empty string that only contains alphabetic 
-- characters
-- */
-- ALTER TABLE "CannedBeans"
-- ADD CONSTRAINT CHK_BeanType
-- CHECK ("BeanType" ~ '^[A-Za-z ]+$' AND "BeanType" <> '');

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

    P_BeanType := TRIM(P_BeanType);

    IF P_Grams <= 0 THEN
        RAISE EXCEPTION 'Grams has to be positive';
    END IF;

    IF P_BeanType = '' OR P_BeanType !~ '^[A-Za-z ]+$' THEN
        RAISE EXCEPTION 'BeanType cannot be empty and must only contain alphabetic characters';
    END IF;

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
    IN P_BeanType VARCHAR(128) DEFAULT NULL,
    IN P_Grams FLOAT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if the record exists
    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', P_CannedBeanID;
    END IF;

    IF P_Grams IS NOT NULL AND P_Grams <= 0 THEN
        RAISE EXCEPTION 'Grams must be positive';
    END IF;

    IF P_BeanType IS NOT NULL THEN
        P_BeanType := TRIM(P_BeanType);
        IF P_BeanType = '' OR P_BeanType !~ '^[A-Za-z ]+$' THEN
            RAISE EXCEPTION 'BeanType cannot be empty and must only contain alphabetic characters';
        END IF;
    END IF;

    -- Performing the update
    UPDATE "CannedBeans"
    SET
        "BeanType" = COALESCE(P_BeanType, "BeanType"),
        "Grams" = COALESCE(P_Grams, "Grams")
    WHERE "CannedBeanID" = P_CannedBeanID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated CannedBeanID %', P_CannedBeanID;
    
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
BEGIN
    -- Checking if the record exists
    IF NOT EXISTS (SELECT 1 FROM "CannedBeans" WHERE "CannedBeanID" = P_CannedBeanID) THEN
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
ALTER COLUMN "SurvivorID" SET NOT NULL;

ALTER TABLE "BeanRequests"
RENAME COLUMN "RequestTime" to "RequestDate";

ALTER TABLE "BeanRequests"
ADD COLUMN "ApprovalDate" DATE DEFAULT NULL;

ALTER TABLE "BeanRequests"
DROP COLUMN "Approved" CASCADE;

ALTER TABLE "BeanRequests"
ADD CONSTRAINT CHK_RequestDate CHECK ("RequestDate" <= CURRENT_DATE),
ADD CONSTRAINT CHK_ApprovalDate
    CHECK ("ApprovalDate" IS NULL OR ("ApprovalDate" >= "RequestDate" AND "ApprovalDate" <= CURRENT_DATE));


/*
BeanRequests Procedures
*/

-- Dropping the old procedures

DROP PROCEDURE IF EXISTS InsertBeanRequest(INTEGER, BOOLEAN, DATE);
DROP PROCEDURE IF EXISTS UpdateBeanRequest(INTEGER, INTEGER, BOOLEAN, DATE);

-- Inserting into BeanRequests

CREATE OR REPLACE PROCEDURE InsertBeanRequest(
    IN P_SurvivorID INTEGER,
    IN P_RequestDate DATE DEFAULT CURRENT_DATE,
    IN P_ApprovalDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if the SurvivorID exists
    IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = P_SurvivorID) THEN
        RAISE EXCEPTION 'SurvivorID % does not exist', P_SurvivorID;
    END IF;

    -- Making sure the request date isn't in the future
    IF P_RequestDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestDate cannot be in the future';
    END IF;

    -- If an approval date was actually given
    IF P_ApprovalDate IS NOT NULL THEN
        -- Approval date cannot be in the future
        IF P_ApprovalDate > CURRENT_DATE THEN
            RAISE EXCEPTION 'ApprovalDate cannot be in the future';
        END IF;

        -- Approval date cannot be before the request date. Like ????
        IF P_ApprovalDate < P_RequestDate THEN
            RAISE EXCEPTION 'A request cannot be approved before it is even issued';
        END IF;
    END IF;

    INSERT INTO "BeanRequests" ("SurvivorID", "ApprovalDate", "RequestDate")
    VALUES (P_SurvivorID, P_ApprovalDate, P_RequestDate);

    RAISE NOTICE 'Successfully inserted bean request for survivor with 
    SurvivorID % on %', P_SurvivorID, P_RequestDate;

    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error inserting bean request: %', SQLERRM;
END;
$$;

-- Updating a record in BeanRequests

CREATE OR REPLACE PROCEDURE UpdateBeanRequest(
    IN P_BeanRequestID INTEGER,
    IN P_SurvivorID INTEGER DEFAULT NULL,
    IN P_RequestDate DATE DEFAULT NULL,
    IN P_ApprovalDate DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Checking if the BeanRequestID exists
    IF NOT EXISTS (SELECT 1 FROM "BeanRequests" WHERE "BeanRequestID" = P_BeanRequestID) THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    END IF;

    -- If SurvivorID is provided, check if it exists
    IF P_SurvivorID IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM "Survivors" WHERE "SurvivorID" = P_SurvivorID) THEN
            RAISE EXCEPTION 'SurvivorID % does not exist', P_SurvivorID;
        END IF;
    END IF;

    -- Ensuring RequestDate is not in the future
    IF P_RequestDate IS NOT NULL AND P_RequestDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestDate cannot be in the future';
    END IF;

    -- If an approval date was actually given
    IF P_ApprovalDate IS NOT NULL THEN
        -- Approval date cannot be in the future
        IF P_ApprovalDate > CURRENT_DATE THEN
            RAISE EXCEPTION 'ApprovalDate cannot be in the future';
        END IF;

        -- Approval date cannot be before the request date. Like ????
        IF P_ApprovalDate < P_RequestDate THEN
            RAISE EXCEPTION 'A request cannot be approved before it is even issued';
        END IF;
    END IF;

    -- Finally perform the BeanRequestUpdate
    UPDATE "BeanRequests"
    SET 
        "SurvivorID" = COALESCE(P_SurvivorID, "SurvivorID"),
        "ApprovalDate" = COALESCE(P_ApprovalDate, "ApprovalDate"),
        "RequestDate" = COALESCE(P_RequestDate, "RequestDate")
    WHERE "BeanRequestID" = P_BeanRequestID;

    -- Success! :)
    RAISE NOTICE 'Successfully updated BeanRequestID %', P_BeanRequestID;

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
BEGIN
    -- Checking if the BeanRequestID exists
    IF NOT EXISTS (SELECT 1 FROM "BeanRequests" WHERE "BeanRequestID" = P_BeanRequestID) THEN
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
    IF NOT EXISTS (SELECT 1 FROM "BeanRequests" WHERE "BeanRequestID" = P_BeanRequestID) THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist', P_BeanRequestID;
    END IF;

    SELECT "ApprovalDate" INTO V_AlreadyApproved FROM "BeanRequests"
    WHERE "BeanRequestID" = P_BeanRequestID;

    -- If already approved, then what are you approving for?? Raise an error!
    IF V_AlreadyApproved IS NOT NULL THEN
        RAISE EXCEPTION 'BeanRequestID % is already approved.', P_BeanRequestID;
    END IF;

    -- Calling the UpdateBeanRequest procedure to approve the request
    CALL UpdateBeanRequest(P_BeanRequestID, NULL, NULL, CURRENT_DATE);

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

CREATE OR REPLACE VIEW ApprovedBeanRequests AS
SELECT
    "BeanRequestID",
    "SurvivorID",
    "RequestDate",
    "ApprovalDate"
FROM "BeanRequests"
WHERE "ApprovalDate" IS NOT NULL;

CREATE OR REPLACE VIEW SurvivorRequestCounts AS
SELECT
    "SurvivorID",
    COUNT("BeanRequestID") AS "TotalRequests"
FROM "BeanRequests"
GROUP BY "SurvivorID";

/*
BeanRequests Functions
*/

CREATE OR REPLACE FUNCTION GetApprovalStatus(BeanRequestID INTEGER)
RETURNS DATE
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT "ApprovalDate" FROM "BeanRequests" WHERE "BeanRequestID" = BeanRequestID;
END;
$$;
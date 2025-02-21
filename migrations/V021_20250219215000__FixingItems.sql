CREATE OR REPLACE FUNCTION GetBottleCaps(
    P_SurvivorID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Caps INTEGER;
BEGIN
    SELECT "BottleCaps" INTO V_Caps
    FROM "Survivors"
    WHERE "SurvivorID" = P_SurvivorID;

    RETURN V_Caps;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ConsumeItem()
RETURNS TRIGGER AS $$
DECLARE
    V_RequestID INTEGER;
    V_SurvivorID INTEGER;
    V_ShelterID INTEGER;
    V_BeanID INTEGER;
    V_Quantity INTEGER;
    V_SupplyID INTEGER;
    V_Caps INTEGER;
BEGIN
    V_RequestID := NEW."BeanRequestID";
    V_BeanID := NEW."CannedBeanID";
    V_Quantity := NEW."NumberOfCans";

    SELECT "SurvivorID" INTO V_SurvivorID FROM "BeanRequests"
    WHERE "BeanRequestID" = V_RequestID LIMIT 1;

    V_ShelterID := GetShelter(V_SurvivorID);

    FOR i IN 1..V_Quantity LOOP
        SELECT "BeanSupplyID" INTO V_SupplyID
        FROM "BeanSupplies"
        WHERE "ShelterID" = V_ShelterID
        AND "CannedBeanID" = V_BeanID
        AND "ConsumedDate" IS NULL
        ORDER BY "BeanSupplyID"
        LIMIT 1;

        Call UpdateBeanSupply(
            V_SupplyID,
            P_ConsumedDate => CURRENT_DATE
        );
    END LOOP;

    V_Caps := GetBottleCaps(V_SurvivorID);

    UPDATE "Survivors"
    SET "BottleCaps" = (V_Caps - V_Quantity)
    WHERE "SurvivorID" = V_SurvivorID;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER ConsumeOnInsert
AFTER INSERT ON "BeanRequestItems"
FOR EACH ROW EXECUTE FUNCTION ConsumeItem();

CREATE OR REPLACE FUNCTION ValidateRequestItemData()
RETURNS TRIGGER AS $$
DECLARE
    V_SurvivorID INTEGER;
    V_ShelterID INTEGER;
    V_NumBeans INTEGER;
    V_BeanType TEXT;
BEGIN
    IF NOT IdExists(NEW."CannedBeanID", 'CannedBeanID', 'CannedBeans') THEN
        RAISE EXCEPTION 'CannedBeanID % does not exist', NEW."CannedBeanID";
    END IF;

    IF NEW."NumberOfCans" <= 0 THEN
      RAISE EXCEPTION 'NumberOfCans has to be a positive integer';
    END IF;

    IF NOT IdExists(NEW."BeanRequestID", 'BeanRequestID', 'BeanRequests') THEN
        RAISE EXCEPTION 'BeanRequestID % does not exist',
        NEW."BeanRequestID";
    END IF;
    
    SELECT "SurvivorID" INTO V_SurvivorID FROM "BeanRequests"
    WHERE "BeanRequestID" = NEW."BeanRequestID";

    IF IsDeceased(V_SurvivorID) THEN
        RAISE EXCEPTION 'Dead people cannot make requests';
    END IF;

    V_ShelterID = GetShelter(V_SurvivorID);

    SELECT COUNT(*)::INTEGER INTO V_NumBeans FROM "BeanSupplies"
    WHERE "ShelterID" = V_ShelterID
    AND "CannedBeanID" = NEW."CannedBeanID"
    AND "ConsumedDate" IS NULL;

    SELECT "BeanType" INTO V_BeanType FROM "CannedBeans"
    WHERE "CannedBeanID" = NEW."CannedBeanID";

    IF (V_NumBeans - NEW."NumberOfCans") < 0 THEN
        RAISE EXCEPTION 'There is not enough stock of % in the shelter''s inventory',
        V_BeanType;
    END IF;

    IF (GetBottleCaps(V_SurvivorID) - NEW."NumberOfCans") < 0 THEN
        RAISE EXCEPTION 'You cannot afford any more cans';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger
DROP TRIGGER IF EXISTS ValidateRequestItem ON "BeanRequestItems";

-- Recreate the trigger on the new table
CREATE TRIGGER ValidateRequestItem BEFORE INSERT ON "BeanRequestItems"
FOR EACH ROW EXECUTE FUNCTION ValidateRequestItemData();
CREATE OR REPLACE FUNCTION SuggestAllowance(
    P_ShelterID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Population INTEGER;
    V_Stock INTEGER;
    V_Min FLOAT;
    V_Suggestion INTEGER;
BEGIN
    V_Population := GetPopulation(P_ShelterID);
    V_Stock := GetStock(P_ShelterID);

    SELECT MIN("Grams") INTO V_Min FROM "CannedBeans";

    V_Suggestion := FLOOR((V_Stock * V_Min) / V_Population);

    IF V_Suggestion < V_Min THEN
        V_Suggestion := V_Min;
    END IF;

    RETURN V_Suggestion;
END;
$$ LANGUAGE plpgsql;

UPDATE "Shelters"
SET "BottleCapAllowance" = CASE
    WHEN "DecommissionDate" IS NULL THEN SuggestAllowance("ShelterID")
    ELSE 0
END;

CREATE OR REPLACE PROCEDURE SetAllowance(
    IN P_ShelterID INTEGER,
    IN P_Limit INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    V_Decom DATE;
BEGIN

    IF NOT IdExists(P_ShelterID, 'ShelterID', 'Shelters') THEN
        RAISE EXCEPTION 'Shelter % does not exist', P_ShelterID;
    END IF;

    SELECT "DecommissionDate" INTO V_Decom FROM "Shelters"
    WHERE "ShelterID" = P_ShelterID LIMIT 1;

    IF V_Decom IS NOT NULL THEN
        RAISE EXCEPTION 'Shelter % has been decommissioned', P_ShelterID;
    END IF;

    IF P_Limit <= 0 THEN
        RAISE EXCEPTION 'Allowance has to be positive';
    END IF;

    IF P_Limit IS NULL THEN
        P_Limit := SuggestAllowance(P_ShelterID);
        RAISE NOTICE 'Using suggested allowance of %',
        SuggestAllowance(P_ShelterID);
    END IF;

    UPDATE "Shelters"
    SET "BottleCapAllowance" = P_Limit
    WHERE "ShelterID" = P_ShelterID;

    RAISE NOTICE 'Successfully update weekly bottlecap allowance for Shelter %',
    P_ShelterID;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error updating weekly bottlecap allowance: %',
            SQLERRM;
END;
$$;
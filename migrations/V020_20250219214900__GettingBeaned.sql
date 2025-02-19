CREATE OR REPLACE FUNCTION GetStock(
    P_ShelterID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Stock INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO V_Stock
    FROM "BeanSupplies"
    WHERE "ShelterID" = P_ShelterID
    AND "ConsumedDate" IS NULL;

    RETURN V_Stock;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetPopulation(
    P_ShelterID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Population INTEGER;
BEGIN
    SELECT COUNT(ss."SurvivorID")::INTEGER INTO V_Population
    FROM "ShelterSurvivors" ss
    JOIN "Survivors" s
    ON ss."SurvivorID" = s."SurvivorID"
    WHERE ss."ShelterID" = P_ShelterID
    AND s."DeceasedDate" IS NULL;

    RETURN V_Population;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetLimit(
    P_ShelterID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Stock INTEGER;
    V_Population INTEGER;
    result INTEGER;
BEGIN
    V_Stock := GetStock(P_ShelterID);
    V_Population := GetPopulation(P_ShelterID);

    result := FLOOR(V_Stock / V_Population);

    IF result = 0 THEN
        result := 1;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION UpdateShelterLimit()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE "Shelters"
    SET "WeeklyLimit" = GetLimit(NEW."ShelterID")
    WHERE "ShelterID" = NEW."ShelterID";

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Trigger_UpdateShelterLimit
AFTER INSERT ON "ShelterSurvivors"
FOR EACH ROW
EXECUTE FUNCTION UpdateShelterLimit();
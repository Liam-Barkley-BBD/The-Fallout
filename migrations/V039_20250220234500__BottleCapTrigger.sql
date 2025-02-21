CREATE OR REPLACE FUNCTION InsertBottleCap()
RETURNS TRIGGER AS $$
DECLARE
    V_SurvivorID INTEGER;
BEGIN
    INSERT INTO "BottleCaps" ("SurvivorID") VALUES (NEW."SurvivorID");

    RAISE NOTICE 'Created BottleCap account for Survivor %', NEW."SurvivorID";

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER CreateBottleCapAccount
AFTER INSERT ON "Survivors"
FOR EACH ROW EXECUTE FUNCTION InsertBottleCap();

CREATE OR REPLACE FUNCTION CheckIfUnique()
RETURNS TRIGGER AS $$
DECLARE
    V_Count INTEGER;
BEGIN

    SELECT COUNT(*)::INTEGER INTO V_Count FROM "BottleCaps"
    WHERE "SurvivorID" = NEW."SurvivorID";

    IF V_Count != 0 THEN
        RAISE EXCEPTION 'Survivor % already has a bottlecap account',
        NEW."SurvivorID";
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER UniqueSurvivorCheck
BEFORE INSERT ON "BottleCaps"
FOR EACH ROW EXECUTE FUNCTION CheckIfUnique();

ALTER TABLE "BottleCaps"
ADD CONSTRAINT CHK_Quantity CHECK ("Quantity" >= 0);

ALTER TABLE "Shelters"
ADD CONSTRAINT CHK_Allowance CHECK ("BottleCapAllowance" >= 0);


CREATE OR REPLACE PROCEDURE SetSurvivorAllowance(
    IN P_SurvivorID INTEGER,
    IN P_Quantity INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT IdExists(P_SurvivorID, 'SurvivorID', 'Survivors') THEN
        RAISE EXCEPTION 'Survivor % does not exist', P_SurvivorID;
    END IF;

    UPDATE "BottleCaps"
    SET "Quantity" = P_Quantity
    WHERE "SurvivorID" = P_SurvivorID;

    RAISE NOTICE 'Successfully set bottlecap quantity for Survivor %',
    P_SurvivorID;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error setting bottlecap quantity: %', SQLERRM;
END;
$$;
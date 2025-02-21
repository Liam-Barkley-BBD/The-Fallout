DROP FUNCTION IF EXISTS GetLimit;
DROP FUNCTION IF EXISTS GetApprovalStatus;

CREATE OR REPLACE FUNCTION UpdateShelterLimit()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE "Shelters"
    SET "BottleCapAllowance" = SuggestAllowance(NEW."ShelterID")
    WHERE "ShelterID" = NEW."ShelterID";

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Trigger_UpdateShelterLimit
AFTER INSERT ON "ShelterSurvivors"
FOR EACH ROW
EXECUTE FUNCTION UpdateShelterLimit();
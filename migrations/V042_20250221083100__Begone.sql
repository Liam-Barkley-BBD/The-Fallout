DROP PROCEDURE IF EXISTS CreateMission(INTEGER, DATE, DATE);
DROP PROCEDURE IF EXISTS ProcessBeanRequest;

CREATE OR REPLACE FUNCTION ValidateBeanRequestData()
RETURNS TRIGGER AS $$
BEGIN
    IF IsDeceased(NEW."SurvivorID") THEN
        RAISE EXCEPTION 'Dead people can''t make bean requests';
    END IF;

    -- Making sure the request date isn't in the future
    IF NEW."RequestDate" > CURRENT_DATE THEN
        RAISE EXCEPTION 'RequestDate cannot be in the future';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER ValidateBeanRequest
BEFORE INSERT OR UPDATE ON "BeanRequests"
FOR EACH ROW EXECUTE FUNCTION ValidateBeanRequestData();
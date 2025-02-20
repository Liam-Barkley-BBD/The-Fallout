ALTER TABLE "Shelters"
RENAME COLUMN "WeeklyLimit" TO "BottleCapAllowance";

/*
Views
*/
DROP VIEW BeanRequestDetails;

CREATE OR REPLACE VIEW BeanRequestDetails AS
SELECT 
    br."RequestDate" AS "Date of Request",
    bri."BeanRequestID",
    s."FirstName" AS "First Name",
    s."LastName" AS "Last Name",
    cb."BeanType",
    bri."NumberOfCans",
    cb."Grams" * bri."NumberOfCans" / 1000 AS "Total Grams (kg)"
FROM "BeanRequestItems" bri
JOIN "CannedBeans" cb ON bri."CannedBeanID" = cb."CannedBeanID"
JOIN "BeanRequests" br ON bri."BeanRequestID" = br."BeanRequestID"
JOIN "Survivors" s ON br."SurvivorID" = s."SurvivorID"
ORDER BY "Date of Request" DESC;

DROP TABLE "BottleCaps";

CREATE TABLE "BottleCaps" (
    "BottleCapID" INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "SurvivorID" INTEGER NOT NULL,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY ("SurvivorID") REFERENCES "Survivors"("SurvivorID") ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION GetBottleCaps(
    P_SurvivorID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    V_Caps INTEGER;
BEGIN
    SELECT "Quantity" INTO V_Caps
    FROM "BottleCaps"
    WHERE "SurvivorID" = P_SurvivorID;

    RETURN V_Caps;
END;
$$ LANGUAGE plpgsql;

DO $$
Begin
FOR i IN 1..150 LOOP
    INSERT INTO "BottleCaps" ("SurvivorID") VALUES (i);
END LOOP;
END $$;
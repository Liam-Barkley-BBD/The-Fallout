WITH 
    TimePeriod AS (
        SELECT INTERVAL '24 months' AS MonthsInterval
    ),
    WeeklyYielded AS (
        SELECT 
            BM."ShelterID",
            DATE_TRUNC('month', BM."YieldDate")::DATE AS "MonthStart",
            (DATE_TRUNC('month', BM."YieldDate") + INTERVAL '1 month')::DATE AS "MonthEnd",
            SUM(MY."NumberOfCans" * CB."Grams") / 1000 AS "TotalYieldKg"
        FROM "BeanMissions" BM
        INNER JOIN "MissionYieldItems" MY ON BM."BeanMissionID" = MY."BeanMissionID"
        INNER JOIN "CannedBeans" CB ON MY."CannedBeanID" = CB."CannedBeanID"
        WHERE BM."YieldDate" >= CURRENT_DATE - (SELECT MonthsInterval FROM TimePeriod)
        GROUP BY BM."ShelterID", "MonthStart", "MonthEnd"
    ),
    WeeklyRequested AS (
        SELECT 
            SS."ShelterID",
            DATE_TRUNC('month', BQ."RequestDate")::DATE AS "MonthStart",
            (DATE_TRUNC('month', BQ."RequestDate") + INTERVAL '1 month')::DATE AS "MonthEnd",
            SUM(BR."NumberOfCans" * CB."Grams") / 1000 AS "TotalRequestedKg"
        FROM "BeanRequests" BQ
        INNER JOIN "BeanRequestItems" BR ON BQ."BeanRequestID" = BR."BeanRequestID"
        INNER JOIN "CannedBeans" CB ON BR."CannedBeanID" = CB."CannedBeanID"
        INNER JOIN "ShelterSurvivors" SS ON BQ."SurvivorID" = SS."SurvivorID"
        WHERE BQ."RequestDate" >= CURRENT_DATE - (SELECT MonthsInterval FROM TimePeriod)
        GROUP BY SS."ShelterID", "MonthStart", "MonthEnd"
    )
SELECT
    COALESCE(WY."ShelterID", WR."ShelterID") AS "ShelterID",
    COALESCE(WY."MonthStart", WR."MonthStart") AS "MonthStart",
    COALESCE(WY."MonthEnd", WR."MonthEnd") AS "MonthEnd",
    COALESCE(WY."TotalYieldKg", 0) AS "TotalYield (kg)",
    COALESCE(WR."TotalRequestedKg", 0) AS "TotalRequested (kg)"
FROM WeeklyYielded WY FULL OUTER JOIN WeeklyRequested WR ON 
    WY."ShelterID" = WR."ShelterID"
    AND WY."MonthStart" = WR."MonthStart"
    AND WY."MonthEnd" = WR."MonthEnd"
ORDER BY "MonthStart" DESC, "ShelterID";
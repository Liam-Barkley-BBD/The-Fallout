WITH 
    TimePeriod AS (
        SELECT INTERVAL '24 months' AS MonthsInterval
    ),
    WeeklyYielded AS (
        SELECT 
            BM."ShelterID",
            DATE_TRUNC('week', BM."YieldDate")::DATE AS "WeekStart",
            (DATE_TRUNC('week', BM."YieldDate") + INTERVAL '6 days')::DATE AS "WeekEnd",
            SUM(MY."NumberOfCans" * CB."Grams") / 1000 AS "TotalYieldKg"
        FROM "BeanMissions" BM
        INNER JOIN "MissionYieldItems" MY ON BM."BeanMissionID" = MY."BeanMissionID"
        INNER JOIN "CannedBeans" CB ON MY."CannedBeanID" = CB."CannedBeanID"
        WHERE BM."YieldDate" >= CURRENT_DATE - (SELECT MonthsInterval FROM TimePeriod)
        GROUP BY BM."ShelterID", "WeekStart", "WeekEnd"
    ),
    WeeklyRequested AS (
        SELECT 
            SS."ShelterID",
            DATE_TRUNC('week', BQ."RequestDate")::DATE AS "WeekStart",
            (DATE_TRUNC('week', BQ."RequestDate") + INTERVAL '6 days')::DATE AS "WeekEnd",
            SUM(BR."NumberOfCans" * CB."Grams") / 1000 AS "TotalRequestedKg"
        FROM "BeanRequests" BQ
        INNER JOIN "BeanRequestItem" BR ON BQ."BeanRequestID" = BR."BeanRequestID"
        INNER JOIN "CannedBeans" CB ON BR."CannedBeanID" = CB."CannedBeanID"
        INNER JOIN "ShelterSurvivors" SS ON BQ."SurvivorID" = SS."SurvivorID"
        WHERE BQ."RequestDate" >= CURRENT_DATE - (SELECT MonthsInterval FROM TimePeriod)
        GROUP BY SS."ShelterID", "WeekStart", "WeekEnd"
    )
SELECT
    COALESCE(WY."ShelterID", WR."ShelterID") AS "ShelterID",
    COALESCE(WY."WeekStart", WR."WeekStart") AS "WeekStart",
    COALESCE(WY."WeekEnd", WR."WeekEnd") AS "WeekEnd",
    COALESCE(WY."TotalYieldKg", 0) AS "TotalYield (kg)",
    COALESCE(WR."TotalRequestedKg", 0) AS "TotalRequested (kg)"
FROM WeeklyYielded WY FULL OUTER JOIN WeeklyRequested WR ON 
    WY."ShelterID" = WR."ShelterID"
    AND WY."WeekStart" = WR."WeekStart"
    AND WY."WeekEnd" = WR."WeekEnd"
ORDER BY "WeekStart" DESC, "ShelterID";
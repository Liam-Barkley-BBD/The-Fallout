-- ============================================
-- SHELTER & POPULATION REPORTS
-- ============================================

-- Active Shelters Overview
-- Retrieves currently active shelters with their capacity, current population, and population utilization.

GO
DROP VIEW IF EXISTS ActiveShelters;

go
CREATE VIEW ActiveShelters
AS
  SELECT *
  FROM "Shelters"
  WHERE "DecommissionDate" is NULL;

GO
DROP VIEW IF EXISTS ActiveSheltersOverview;

GO
CREATE VIEW ActiveSheltersOverview
AS
  WITH
    ShelterCannedBeans
    AS
    (
      SELECT
        bs."ShelterID",
        cb."CannedBeanID",
        SUM ("Grams") AS "TotalGramsOfBeans"
      FROM
        "BeanSupplies" bs
        INNER JOIN "CannedBeans" cb ON bs."CannedBeanID" = cb."CannedBeanID"
      GROUP BY
        bs."ShelterID",
        cb."CannedBeanID"
    ),
    ShelterPopulation
    AS
    (
    	 SELECT
    		acts."ShelterID",
    		COUNT (ss."SurvivorID") AS "Population"
    	FROM
    		ActiveShelters acts
    		INNER JOIN "ShelterSurvivors" ss ON ss."ShelterID" = acts."ShelterID"
		group by acts."ShelterID"
    )
  SELECT
    active."ShelterID",
    active."PopulationCapacity",
    active."Latitude",
    active."Longitude",
    active."EstablishedDate",
    scb."TotalGramsOfBeans",
    sp."Population",
    (sp."Population"::float8 / active."PopulationCapacity"::float8) AS "PopulationUtilization"
  FROM
    ActiveShelters active
    INNER JOIN ShelterPopulation sp ON active."ShelterID" = sp."ShelterID"
    INNER JOIN ShelterCannedBeans scb ON active."ShelterID" = scb."ShelterID"

-- Decommissioned Shelters
-- Lists shelters that have been decommissioned, including their operational duration.

GO
DROP VIEW IF EXISTS DecommissionedShelters;

GO
CREATE VIEW DecommissionedShelters
AS
  SELECT
    shelters."ShelterID",
    shelters."PopulationCapacity",
    shelters."Latitude",
    shelters."Longitude",
    shelters."EstablishedDate",
    shelters."DecommissionDate",
    (shelters."DecommissionDate" - shelters."EstablishedDate") AS "DaysInOperation"
  FROM "Shelters" shelters
  WHERE "DecommissionDate" is NOT NULL;

-- Shelter Managers Report
-- Displays managers assigned to each shelter.

 SELECT 
	m."ManagerID",
	m."SurvivorID",
	s."BirthDate",
	s."DeceasedDate",
	s."FirstName",
	s."LastName" 
FROM "Managers" m
INNER JOIN "Survivors" s ON m."SurvivorID" = s."SurvivorID" 


-- ============================================
-- SURVIVOR REPORTS
-- ============================================

-- Survivor Demographics
-- Provides a breakdown of survivors by age group, shelter, and overall population trends.

 SELECT 
	s."SurvivorID",
	s."FirstName",
	s."LastName",
	s."BirthDate",
	CASE
      WHEN s."BirthDate" between NOW() - interval '18 years' and NOW() THEN 'Child'
      WHEN s."BirthDate" between NOW() - interval '60 years' and NOW() THEN 'Adult'
      else 'Pensioner'
	end AS "AgeGroup"
FROM "Survivors" s 
where s."DeceasedDate" is NULL 
	
---
create or replace function getPeriods
(
	endDate Date default NOW()::Date,
	intervals INTERVAL default '3 Months'::INTERVAL,
	numPeriods integer default 4
)
   returns setof record
   language sql
  AS
$$
   WITH
	RECURSIVE Periods
	AS 
	(
		 SELECT 1 AS "PeriodNumber", endDate::DATE AS "LastDate", (endDate - intervals)::DATE AS "FirstDate", numPeriods AS "NumPeriods"
		union all
		 SELECT (1+ "PeriodNumber") AS "PeriodNumber", ("FirstDate" - interval '1 DAY')::DATE AS "LastDate", ("LastDate" - intervals)::DATE AS "FirstDate", "NumPeriods"
		FROM Periods
		where "PeriodNumber" < "NumPeriods"
	)
	 SELECT * FROM Periods;
$$;

-- Shows total number of cans and grams of beans accumulated through
-- missions by a shelter over a n periods of time leading up to today
WITH 
	Periods
	AS
	(
		 SELECT * FROM getPeriods(NOW()::DATE, interval '1 month', 24) AS t("PeriodNumber" INT, "PeriodEndDate" DATE, "PeriodStartDate" DATE, "NumPeriods" INT)
	),
	PeriodicBeanMissions
	AS
	(
	 SELECT 
		bm."BeanMissionID",
		bm."ShelterID",
		bm."StartDate",
		bm."EndDate",
		p."PeriodNumber",
		p."PeriodEndDate",
		p."PeriodStartDate", 
		p."NumPeriods"
	FROM 
		"BeanMissions" bm
		INNER JOIN Periods p ON bm."EndDate" between p."PeriodStartDate" and p."PeriodEndDate" --+ interval '1 day'
	),
	MissionYieldSummary
	AS
	(
		 SELECT 
			myi."BeanMissionID",
			SUM(myi."NumberOfCans") AS "TotalNumberOfCans",
			SUM (myi."NumberOfCans" * cb."Grams") AS "TotalGramsOfBeans"
		FROM "MissionYieldItems" myi 
		INNER JOIN "CannedBeans" cb ON cb."CannedBeanID" = myi."CannedBeanID"
		group by myi."BeanMissionID"
	),
	FullMissionYieldSummary
	AS 
	(
		 SELECT "BeanMissionID", "TotalNumberOfCans", "TotalGramsOfBeans" FROM MissionYieldSummary
		union ALL
		 SELECT 
			bm."BeanMissionID",
			0 AS "TotalNumberOfCans",
			0 AS "TotalGramsOfBeans"
		FROM "BeanMissions" bm
		WHERE NOT EXISTS (
   			 SELECT 1 FROM MissionYieldSummary mys WHERE mys."BeanMissionID" = bm."BeanMissionID"
		)
	),
	PeriodicBeanMissionYields
	AS
	(
		 SELECT distinct
			pbm."ShelterID",
			pbm."StartDate",
			pbm."EndDate",
			pbm."PeriodNumber",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."NumPeriods",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		FROM 
			PeriodicBeanMissions pbm
			INNER JOIN FullMissionYieldSummary fmys ON pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	CombinedMissionYieldsForPeriod
	AS
	(
		 SELECT
			pbm."ShelterID",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."PeriodNumber",
			pbm."EndDate",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		FROM 
			PeriodicBeanMissions pbm
			INNER JOIN FullMissionYieldSummary fmys ON pbm."BeanMissionID" = fmys."BeanMissionID"
	)
 SELECT * FROM CombinedMissionYieldsForPeriod

	
-------------------------------------------------
	
create or replace function getFuturePeriods
(
	startDate Date default NOW()::Date,
	intervals INTERVAL default '3 Months'::INTERVAL,
	numPeriods integer default 4
)
   returns setof record
   language sql
  AS
$$
   WITH
	RECURSIVE Periods
	AS 
	(
		 SELECT 1 AS "PeriodNumber", startDate::DATE AS "PeriodStartDate", (startDate + intervals)::DATE AS "PeriodEndDate", numPeriods AS "NumPeriods"
		union all
		 SELECT (1+ "PeriodNumber") AS "PeriodNumber", ("PeriodEndDate" + interval '1 DAY')::DATE AS "PeriodStartDate", ("PeriodEndDate" + intervals)::DATE AS "PeriodEndDate", "NumPeriods"
		FROM Periods
		where "PeriodNumber" < "NumPeriods"
	)
	 SELECT * FROM Periods;
$$;
	
-- y = ax + b
-- total number of beans = regr_slope(historical number of beans, periodEndDate) current currentDate + regr_intercept(historical number of beans, periodEndDate)

-- Shows projected total number of cans and grams of beans accumulated through
-- missions by a shelter over a n periods of time into the future starting FROM today
-- the query uses simple linear regression to predict future values
select * from "MissionYieldItems"
WITH 
	Periods
	AS
	(
	 SELECT * FROM getPeriods(NOW()::DATE, interval '1 month', 24) AS t("PeriodNumber" INT, "PeriodEndDate" DATE, "PeriodStartDate" DATE, "NumPeriods" INT)
	),
	PeriodicBeanMissions
	AS
	(
	 SELECT 
		bm."BeanMissionID",
		bm."ShelterID",
		bm."StartDate",
		bm."EndDate",
		p."PeriodNumber",
		p."PeriodEndDate",
		p."PeriodStartDate", 
		p."NumPeriods"
	FROM 
		"BeanMissions" bm
		INNER JOIN Periods p ON bm."EndDate" between p."PeriodStartDate" and p."PeriodEndDate" --+ interval '1 day'
	),
	MissionYieldSummary
	AS
	(
		 SELECT 
			myi."BeanMissionID",
			SUM(myi."NumberOfCans") AS "TotalNumberOfCans",
			SUM (myi."NumberOfCans" * cb."Grams") AS "TotalGramsOfBeans"
		FROM "MissionYieldItems" myi 
		INNER JOIN "CannedBeans" cb ON cb."CannedBeanID" = myi."CannedBeanID"
		group by myi."BeanMissionID"
	),
	FullMissionYieldSummary
	AS 
	(
		 SELECT "BeanMissionID", "TotalNumberOfCans", "TotalGramsOfBeans" FROM MissionYieldSummary
		union ALL
		 SELECT 
			bm."BeanMissionID",
			0 AS "TotalNumberOfCans",
			0 AS "TotalGramsOfBeans"
		FROM "BeanMissions" bm
		WHERE NOT EXISTS (
   			 SELECT 1 FROM MissionYieldSummary mys WHERE mys."BeanMissionID" = bm."BeanMissionID"
		)
	),
	PeriodicBeanMissionYields
	AS
	(
		 SELECT distinct
			pbm."ShelterID",
			pbm."StartDate",
			pbm."EndDate",
			pbm."PeriodNumber",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."NumPeriods",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		FROM 
			PeriodicBeanMissions pbm
			INNER JOIN FullMissionYieldSummary fmys ON pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	CombinedMissionYieldsForPeriod
	AS
	(
		 SELECT
			pbm."ShelterID",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."PeriodNumber",
			pbm."EndDate",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		FROM 
			PeriodicBeanMissions pbm
			INNER JOIN FullMissionYieldSummary fmys ON pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	RegressionCoefficientsForShelter24 
	AS 
	(
		 SELECT
			hd."ShelterID",
			regr_slope(hd."TotalNumberOfCans"::Int, extract(epoch FROM (hd."PeriodEndDate"))::INT) AS "SlopeCans",
			regr_intercept(hd."TotalNumberOfCans"::Int, extract(epoch FROM (hd."PeriodEndDate"))::INT) AS "InterceptCans",
			regr_slope(hd."TotalGramsOfBeans"::Int, extract(epoch FROM (hd."PeriodEndDate"))::INT) AS "SlopeGrams",
			regr_intercept(hd."TotalGramsOfBeans"::Int, extract(epoch FROM (hd."PeriodEndDate"))::INT) AS "InterceptGrams"
		FROM 
			( SELECT * FROM CombinedMissionYieldsForPeriod cmyfp
			) AS hd
		where hd."TotalGramsOfBeans" > 0 and hd."TotalGramsOfBeans" > 0
		group by
			hd."ShelterID"
	),
	FuturePeriods
	AS
	(
	 SELECT * FROM getFuturePeriods(NOW()::DATE, interval '1 month', 24) AS t("PeriodNumber" INT, "PeriodStartDate" DATE, "PeriodEndDate" DATE, "NumPeriods" INT)
	),
	MissionYieldProjections
	AS
	(
		 SELECT 
			rc."ShelterID",
			fp."PeriodNumber", 
			fp."PeriodStartDate", 
			fp."PeriodEndDate", 
			fp."NumPeriods",
			rc."SlopeCans",
			rc."SlopeGrams",
			rc."InterceptCans",
			rc."InterceptGrams",
			(rc."SlopeCans" * extract(epoch FROM (fp."PeriodEndDate")::TIMESTAMP)::INT + rc."InterceptCans") AS "ProjectedTotalNumberOfCans",
			(rc."SlopeGrams" * extract(epoch FROM (fp."PeriodEndDate")::TIMESTAMP)::INT + rc."InterceptGrams") AS "ProjectedTotalGramsOfBeans"
		FROM 
			RegressionCoefficientsForShelter24 rc
			CROSS JOIN FuturePeriods fp
	)
 SELECT * FROM MissionYieldProjections

-- y = ax + b
-- total number of beans = regr_slope(historical number of beans, periodEndDate) current currentDate + regr_intercept(historical number of beans, periodEndDate)

	
-- ============================================
-- SHELTER & POPULATION REPORTS
-- ============================================

-- Active Shelters Overview
-- Retrieves currently active shelters with their capacity, current population, and supply levels.

GO
DROP VIEW IF EXISTS ActiveShelters;

GO
CREATE VIEW ActiveShelters
AS
  SELECT *
  FROM "Shelters"
  WHERE "DecommisionDate" is NULL;

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
    as
    (
    	select
    		acts."ShelterID",
    		COUNT (ss."SurvivorID") as "Population"
    	from
    		ActiveShelters acts
    		inner join "ShelterSurvivors" ss on ss."ShelterID" = acts."ShelterID"
		group by acts."ShelterID"
    )
  SELECT
    active."ShelterID",
    active."PopulationCapacity",
    active."SupplyVolume",
    active."Latitude",
    active."Longitude",
    active."EstablishedDate",
    scb."TotalGramsOfBeans",
    sp."Population",
    (scb."TotalGramsOfBeans" / active."SupplyVolume") as "StorageUtilization",
    (sp."Population"::float8 / active."PopulationCapacity"::float8) as "PopulationUtilization"
  FROM
    ActiveShelters active
    INNER JOIN ShelterPopulation sp ON active."ShelterID" = sp."ShelterID"
    INNER JOIN ShelterCannedBeans scb ON active."ShelterID" = scb."ShelterID"

GO
SELECT * FROM ActiveSheltersOverview

-- Shelter Population Report
-- Shows the number of survivors per shelter along with capacity utilization.

GO
DROP VIEW IF EXISTS ShelterPopulationReport

GO
CREATE VIEW ShelterPopulationReport
AS
  SELECT
    aso."ShelterID",
    aso."PopulationCapacity",
    aso."Population",
    (aso."Population"::float8 / aso."PopulationCapacity"::float8) AS "PopulationCapacityUtilization"
  FROM ActiveSheltersOverview aso

-- Shelter Supply Levels
-- Summarizes available supplies in each shelter, including canned beans and other relevant resources.
  
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
    shelters."SupplyVolume",
    shelters."Latitude",
    shelters."Longitude",
    shelters."EstablishedDate",
    shelters."DecommisionDate",
    (shelters."DecommisionDate" - shelters."EstablishedDate") AS "DaysInOperation"
  FROM "Shelters" shelters
  WHERE "DecommisionDate" is NOT NULL;

-- Shelter Managers Report
-- Displays managers assigned to each shelter.

select 
	m."ManagerID",
	m."SurvivorID",
	s."BirthDate",
	s."DeceasedDate",
	s."FirstName",
	s."LastName" 
from "Managers" m
inner join "Survivors" s on m."SurvivorID" = s."SurvivorID" 


-- ============================================
-- SURVIVOR REPORTS
-- ============================================

-- Survivor Demographics
-- Provides a breakdown of survivors by age group, shelter, and overall population trends.

select 
	s."SurvivorID",
	s."FirstName",
	s."LastName",
	s."BirthDate",
	CASE
      WHEN s."BirthDate" between NOW() - interval '18 years' and NOW() THEN 'Child'
      WHEN s."BirthDate" between NOW() - interval '60 years' and NOW() THEN 'Adult'
      else 'Pensioner'
	end as "AgeGroup"
from "Survivors" s 
where s."DeceasedDate" is NULL

-- ============================================
-- BEAN SUPPLY & DISTRIBUTION REPORTS
-- ============================================

-- Bean Requests Status Report
-- Displays pending and approved bean requests by survivors.

-- Bean Supply Inventory
-- Shows the current stock of canned beans at each shelter.

-- Bean Consumption History
-- Provides a record of all consumed canned beans by shelter and date.

-- Bean Request vs. Supply Analysis
-- Compares total requested beans vs. supplied beans per shelter. 
	

-- ============================================
-- MISSION REPORTS
-- ============================================

-- Average Time between missions per shelter

-- Upcoming Bean Missions
-- Lists planned bean delivery missions with start and end dates.

-- Completed Bean Missions & Yields
-- Displays completed missions, including the number of beans delivered.

-- Mission Efficiency Report
-- Compares planned vs. actual completion times for bean missions.

-- Bean Yield Analysis
-- Breaks down bean types and quantities collected from missions.

-- ============================================
-- PERFORMANCE & TRENDS REPORTS
-- ============================================

-- Shelter Population Growth Trends
-- Shows population trends over time for each shelter.

-- Bean Supply & Demand Trends
-- Analyzes patterns of bean requests and consumption over time.


-- Shelter Performance Report
-- Compares shelters based on resource efficiency, population stability, and management effectiveness.

create or replace function getPeriods
(
	endDate Date default NOW()::Date,
	intervals INTERVAL default '3 Months'::INTERVAL,
	numPeriods integer default 4
)
   returns setof record
   language sql
  as
$$
   with
	RECURSIVE Periods
	as 
	(
		select 1 as "PeriodNumber", endDate::DATE as "LastDate", (endDate - intervals)::DATE as "FirstDate", numPeriods as "NumPeriods"
		union all
		select (1+ "PeriodNumber") as "PeriodNumber", ("FirstDate" - interval '1 DAY')::DATE as "LastDate", ("LastDate" - intervals)::DATE as "FirstDate", "NumPeriods"
		from Periods
		where "PeriodNumber" < "NumPeriods"
	)
	select * from Periods;
$$;

-- Shows total number of cans and grams of beans accumulated through
-- missions by a shelter over a n periods of time leading up to today
with 
	Periods
	as
	(
	select * from getPeriods(NOW()::DATE, interval '1 month', 24) as t("PeriodNumber" INT, "PeriodEndDate" DATE, "PeriodStartDate" DATE, "NumPeriods" INT)
	),
	PeriodicBeanMissions
	as
	(
	select 
		bm."BeanMissionID",
		bm."ShelterID",
		bm."StartDate",
		bm."EndDate",
		p."PeriodNumber",
		p."PeriodEndDate",
		p."PeriodStartDate", 
		p."NumPeriods"
	from 
		"BeanMissions" bm
		inner join Periods p on bm."EndDate" between p."PeriodStartDate" and p."PeriodEndDate" --+ interval '1 day'
	),
	MissionYieldSummary
	as
	(
		select 
			myi."BeanMissionID",
			SUM(myi."NumberOfCans") as "TotalNumberOfCans",
			SUM (myi."NumberOfCans" * cb."Grams") as "TotalGramsOfBeans"
		from "MissionYieldItems" myi 
		inner join "CannedBeans" cb on cb."CannedBeanID" = myi."CannedBeanID"
		group by myi."BeanMissionID"
	),
	FullMissionYieldSummary
	as 
	(
		select "BeanMissionID", "TotalNumberOfCans", "TotalGramsOfBeans" from MissionYieldSummary
		union ALL
		select 
			bm."BeanMissionID",
			0 as "TotalNumberOfCans",
			0 as "TotalGramsOfBeans"
		from "BeanMissions" bm
		WHERE NOT EXISTS (
   			 SELECT 1 FROM MissionYieldSummary mys WHERE mys."BeanMissionID" = bm."BeanMissionID"
		)
	),
	PeriodicBeanMissionYields
	as
	(
		select distinct
			pbm."ShelterID",
			pbm."StartDate",
			pbm."EndDate",
			pbm."PeriodNumber",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."NumPeriods",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		from 
			PeriodicBeanMissions pbm
			inner join FullMissionYieldSummary fmys on pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	CombinedMissionYieldsForPeriod
	as
	(
		select
			pbm."ShelterID",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."PeriodNumber",
			pbm."EndDate",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		from 
			PeriodicBeanMissions pbm
			inner join FullMissionYieldSummary fmys on pbm."BeanMissionID" = fmys."BeanMissionID"
	)
select * from CombinedMissionYieldsForPeriod

select * from "BeanMissions" bm 
	
	-------------------------------------------------
	
create or replace function getFuturePeriods
(
	startDate Date default NOW()::Date,
	intervals INTERVAL default '3 Months'::INTERVAL,
	numPeriods integer default 4
)
   returns setof record
   language sql
  as
$$
   with
	RECURSIVE Periods
	as 
	(
		select 1 as "PeriodNumber", startDate::DATE as "PeriodStartDate", (startDate + intervals)::DATE as "PeriodEndDate", numPeriods as "NumPeriods"
		union all
		select (1+ "PeriodNumber") as "PeriodNumber", ("PeriodEndDate" + interval '1 DAY')::DATE as "PeriodStartDate", ("PeriodEndDate" + intervals)::DATE as "PeriodEndDate", "NumPeriods"
		from Periods
		where "PeriodNumber" < "NumPeriods"
	)
	select * from Periods;
$$;
	

select * from getFuturePeriods(NOW()::DATE, interval '1 month', 4) as t("PeriodNumber" INT, "PeriodStartDate" DATE, "PeriodEndDate" DATE, "NumPeriods" INT)

-- y = ax + b
-- total number of beans = regr_slope(historical number of beans, periodEndDate) current currentDate + regr_intercept(historical number of beans, periodEndDate)

-- Shows projected total number of cans and grams of beans accumulated through
-- missions by a shelter over a n periods of time into the future starting from today
-- the query uses simple linear regression to predict future values
with 
	Periods
	as
	(
	select * from getPeriods(NOW()::DATE, interval '1 month', 24) as t("PeriodNumber" INT, "PeriodEndDate" DATE, "PeriodStartDate" DATE, "NumPeriods" INT)
	),
	PeriodicBeanMissions
	as
	(
	select 
		bm."BeanMissionID",
		bm."ShelterID",
		bm."StartDate",
		bm."EndDate",
		p."PeriodNumber",
		p."PeriodEndDate",
		p."PeriodStartDate", 
		p."NumPeriods"
	from 
		"BeanMissions" bm
		inner join Periods p on bm."EndDate" between p."PeriodStartDate" and p."PeriodEndDate" --+ interval '1 day'
	),
	MissionYieldSummary
	as
	(
		select 
			myi."BeanMissionID",
			SUM(myi."NumberOfCans") as "TotalNumberOfCans",
			SUM (myi."NumberOfCans" * cb."Grams") as "TotalGramsOfBeans"
		from "MissionYieldItems" myi 
		inner join "CannedBeans" cb on cb."CannedBeanID" = myi."CannedBeanID"
		group by myi."BeanMissionID"
	),
	FullMissionYieldSummary
	as 
	(
		select "BeanMissionID", "TotalNumberOfCans", "TotalGramsOfBeans" from MissionYieldSummary
		union ALL
		select 
			bm."BeanMissionID",
			0 as "TotalNumberOfCans",
			0 as "TotalGramsOfBeans"
		from "BeanMissions" bm
		WHERE NOT EXISTS (
   			 SELECT 1 FROM MissionYieldSummary mys WHERE mys."BeanMissionID" = bm."BeanMissionID"
		)
	),
	PeriodicBeanMissionYields
	as
	(
		select distinct
			pbm."ShelterID",
			pbm."StartDate",
			pbm."EndDate",
			pbm."PeriodNumber",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."NumPeriods",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		from 
			PeriodicBeanMissions pbm
			inner join FullMissionYieldSummary fmys on pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	CombinedMissionYieldsForPeriod
	as
	(
		select
			pbm."ShelterID",
			pbm."PeriodStartDate",
			pbm."PeriodEndDate",
			pbm."PeriodNumber",
			pbm."EndDate",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		from 
			PeriodicBeanMissions pbm
			inner join FullMissionYieldSummary fmys on pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	RegressionCoefficientsForShelter24 
	as 
	(
		select
			hd."ShelterID",
			regr_slope(hd."TotalNumberOfCans"::Int, extract(epoch from (hd."PeriodEndDate"))::INT) as "SlopeCans",
			regr_intercept(hd."TotalNumberOfCans"::Int, extract(epoch from (hd."PeriodEndDate"))::INT) as "InterceptCans",
			regr_slope(hd."TotalGramsOfBeans"::Int, extract(epoch from (hd."PeriodEndDate"))::INT) as "SlopeGrams",
			regr_intercept(hd."TotalGramsOfBeans"::Int, extract(epoch from (hd."PeriodEndDate"))::INT) as "InterceptGrams"
		from 
			(select * from CombinedMissionYieldsForPeriod cmyfp
			) as hd
		where hd."TotalGramsOfBeans" > 0 and hd."TotalGramsOfBeans" > 0
		group by
			hd."ShelterID"
	),
	FuturePeriods
	as
	(
	select * from getFuturePeriods(NOW()::DATE, interval '1 month', 24) as t("PeriodNumber" INT, "PeriodStartDate" DATE, "PeriodEndDate" DATE, "NumPeriods" INT)
	),
	MissionYieldProjections
	as
	(
		select 
			rc."ShelterID",
			fp."PeriodNumber", 
			fp."PeriodStartDate", 
			fp."PeriodEndDate", 
			fp."NumPeriods",
			rc."SlopeCans",
			rc."SlopeGrams",
			rc."InterceptCans",
			rc."InterceptGrams",
			(rc."SlopeCans" * extract(epoch from (fp."PeriodEndDate")::TIMESTAMP)::INT + rc."InterceptCans") as "ProjectedTotalNumberOfCans",
			(rc."SlopeGrams" * extract(epoch from (fp."PeriodEndDate")::TIMESTAMP)::INT + rc."InterceptGrams") as "ProjectedTotalGramsOfBeans"
		from 
			RegressionCoefficientsForShelter24 rc
			cross join FuturePeriods fp
	)
--select * from RegressionCoefficientsForShelter24
select * from MissionYieldProjections
--select 
--	cmyfp."ShelterID", cmyfp."PeriodStartDate", cmyfp."PeriodEndDate", cmyfp."PeriodNumber", cmyfp."EndDate", 
--	cmyfp."TotalNumberOfCans", cmyfp."TotalGramsOfBeans",
--	(extract(epoch from (cmyfp."PeriodEndDate")::TIMESTAMP)::INT) as x
--from CombinedMissionYieldsForPeriod cmyfp where cmyfp."ShelterID" = 24 order by cmyfp."PeriodEndDate"

-- y = ax + b
-- total number of beans = regr_slope(historical number of beans, periodEndDate) current currentDate + regr_intercept(historical number of beans, periodEndDate)

	
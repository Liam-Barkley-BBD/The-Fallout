-- TODO: Use SELECT interval instead
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
		bm."YieldDate",
		p."PeriodNumber",
		p."PeriodEndDate",
		p."PeriodStartDate", 
		p."NumPeriods"
	FROM 
		"BeanMissions" bm
		INNER JOIN Periods p ON bm."YieldDate" between p."PeriodStartDate" and p."PeriodEndDate" --+ interval '1 day'
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
			pbm."YieldDate",
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
			pbm."YieldDate",
			fmys."TotalNumberOfCans",
			fmys."TotalGramsOfBeans"
		FROM 
			PeriodicBeanMissions pbm
			INNER JOIN FullMissionYieldSummary fmys ON pbm."BeanMissionID" = fmys."BeanMissionID"
	),
	RegressionCoefficientsForShelter
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
			RegressionCoefficientsForShelter rc
			CROSS JOIN FuturePeriods fp
	)
 SELECT * FROM MissionYieldProjections
where "ShelterID" = 24
-- y = ax + b
-- total number of beans = regr_slope(historical number of beans, periodEndDate) current currentDate + regr_intercept(historical number of beans, periodEndDate)

	
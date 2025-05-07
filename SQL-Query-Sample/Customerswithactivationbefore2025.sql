--This script finds active subscribers with an activation date before 2015 and their current product.

SELECT DISTINCT
       sc.ServiceID
	   ,s.SK_StatusValue_Service
	   ,s.SK_Date_Activation
	   ,s.SK_Bundle
INTO #OldSubscribers
FROM fct.Subscriber s
LEFT JOIN dim.vSimCard sc
    ON sc.SK_SimCard = s.SK_SimCard
WHERE s.SK_Date_Activation <= 20250206
AND   s.SK_Date_Activation > 0
AND   (   s.SK_Date_Deactivation > 20250206
    OR    s.SK_Date_Deactivation = -1)
AND   s.SK_Date_SignupCancellation = -1
AND   s.SK_Date_Start <= 20250206
AND   s.SK_Date_End > 20250206
AND   s.SK_Date_Activation < 20150206

-- Joining Status and product onto the list --

SELECT
	ServiceID
	,SK_Date_Activation
	,SV.Status
	,BundleGroupLevel0
FROM #OldSubscribers
LEFT JOIN
dim.vStatusValue SV ON #OldSubscribers.SK_StatusValue_Service = SV.SK_StatusValue
LEFT JOIN 
dim.vBundle B ON #OldSubscribers.SK_Bundle = B.SK_Bundle

ORDER BY SK_Date_Activation ASC

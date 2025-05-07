--This script finds customers that has a bNPS survey.

DROP TABLE IF EXISTS #ListNPSCustomers;

-- Collecting phone number and interview date from ds.NPS --
SELECT 
	Phone
	,interview_end
	,Survey_Type
	,CONVERT(VARCHAR(8), interview_end, 112) AS interviewDate
INTO #ListNPSCustomers

FROM ds.NPS
-- Only bNPS surverys --
WHERE Survey_Type LIKE '%bNPS'

-- remove countrycode from phone number and convert interview timestamp to date only --

UPDATE #ListNPSCustomers
SET Phone = RIGHT(Phone, 8)

-- Insert into new list --
DROP TABLE IF EXISTS #ListNPSWithServiceID;

SELECT 
	Phone
	,interview_end
	,Survey_Type
	,interviewDate
	,ServiceID
	,SK_SimCard

INTO #ListNPSWithServiceID
FROM #ListNPSCustomers
LEFT JOIN
	dim.vSimcard S ON #ListNPSCustomers.Phone = S.MasterPhonenumber


-- Join columns from fact subscriber --
SELECT
	Phone
	,interview_end
	,Survey_Type
	,interviewDate
	,ServiceID
	,SK_Date_Start
	,SK_Date_End

FROM #ListNPSWithServiceID
LEFT JOIN
	fct.vSubscriber Sub ON #ListNPSWithServiceID.SK_SimCard = Sub.SK_SimCard

WHERE interviewDate >= 20240101
AND interviewDate BETWEEN SK_Date_Start AND SK_Date_End

ORDER BY Phone ASC

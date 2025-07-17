CREATE VIEW ds.DCX_AktiveProdukter AS 
/* 
This table returns active customers and certain information about about them.
*/
SELECT 
	ServiceID,
	CustomerID,
	Company,
	PrepaidEmail,
	MasterPhonenumber,
	BundleName,
	ServiceAccountStatus,
	AccountLabel,
	ENUM.e_data AS AlertGroupName
FROM (SELECT
	ServiceID,
	CustomerID,
	Company,
	PrepaidEmail,
	PrepaidID,
	MasterPhonenumber,
	BundleKey AS BundleName,
	StatusValue.Status
FROM (SELECT DISTINCT SK_SimCard, SK_Bundle, SK_Customer, SK_StatusValue_Service
             FROM fct.vSubscriber s
             WHERE s.SK_Date_Activation <= 20250716
             AND   s.SK_Date_Activation > 0
             AND   (   s.SK_Date_Deactivation > 20250716
                 OR    s.SK_Date_Deactivation = -1)
             AND   s.SK_Date_SignupCancellation = -1
             AND   s.SK_Date_Start <= 20250716
             AND   s.SK_Date_End > 20250716) ActiveSimcards
LEFT JOIN dim.vSimCard SIM ON ActiveSimcards.SK_SimCard = SIM.SK_SimCard
LEFT JOIN dim.vBundle Bundle ON ActiveSimcards.SK_Bundle = Bundle.SK_Bundle
LEFT JOIN dim.vCustomer Customer ON ActiveSimcards.SK_Customer = Customer.SK_Customer
LEFT JOIN dim.vStatusValue StatusValue ON ActiveSimcards.SK_StatusValue_Service = StatusValue.SK_StatusValue) CustomerInfo
LEFT JOIN DatabaseStaging.schema.ServiceAccountView SAV ON CustomerInfo.ServiceID = SAV.id_acc and SAV.PKLatest = 1 --Service Account ID
LEFT JOIN DatabaseStaging.schema.accountalertgroup Alert ON CustomerInfo.PrepaidID = Alert.id_acc and Alert.PKLatest = 1 --Prepaid ID
LEFT JOIN DatabaseEDW.calc.NM_enum_data ENUM ON Alert.c_AlertGroup = ENUM.id_enum_data


--- Or using temp tables:

--- Find active subscribers and relevant surrogate keys.
DROP TABLE IF EXISTS #ActiveSimcards
SELECT DISTINCT SK_SimCard, SK_Bundle, SK_Customer, SK_StatusValue_Service
INTO #ActiveSimcards
             FROM fct.Subscriber s
             WHERE s.SK_Date_Activation <= 20250716
             AND   s.SK_Date_Activation > 0
             AND   (   s.SK_Date_Deactivation > 20250716
                 OR    s.SK_Date_Deactivation = -1)
             AND   s.SK_Date_SignupCancellation = -1
             AND   s.SK_Date_Start <= 20250716
             AND   s.SK_Date_End > 20250716


DROP TABLE IF EXISTS #CustomerInfo
SELECT
	ServiceID,
	CustomerID,
	Company,
	PrepaidEmail,
	PrepaidID,
	MasterPhonenumber,
	BundleName,
	StatusValue.Status
INTO #CustomerInfo
FROM #ActiveSimcards
LEFT JOIN dim.SimCard SIM ON #ActiveSimcards.SK_SimCard = SIM.SK_SimCard
LEFT JOIN dim.Bundle Bundle ON #ActiveSimcards.SK_Bundle = Bundle.SK_Bundle
LEFT JOIN dim.Customer Customer ON #ActiveSimcards.SK_Customer = Customer.SK_Customer
LEFT JOIN dim.StatusValue StatusValue ON #ActiveSimcards.SK_StatusValue_Service = StatusValue.SK_StatusValue

SELECT 
	ServiceID,
	CustomerID,
	Company,
	PrepaidEmail,
	MasterPhonenumber,
	BundleName,
	AccountStatus,
	AccountLabel,
	AlertGroup
FROM #CustomerInfo
LEFT JOIN DatabaseStaging.schema.ServiceAccountView SAV ON #CustomerInfo.ServiceID = SAV.id_acc and SAV.PKLatest = 1 --Service Account ID
LEFT JOIN DatabaseStaging.schema.accountalertgroup Alert ON #CustomerInfo.PrepaidID = Alert.id_acc and Alert.PKLatest = 1 --Prepaid ID
LEFT JOIN calc.enumdata ENUM ON Alert.c_AlertGroup = ENUM.id_enum_data

--This script finds all compensations given to customers.

-- Join ServiceID, product, Posting Type and activation+cancellation dato on table --

DROP TABLE IF EXISTS #Compensationlist;

SELECT 
      Comp.SK_SimCard
	  ,ServiceID
	  ,SK_Date_Compensation
      ,ProductLevel1
	  ,ProductLevel2
	  ,ProductLevel3
	  ,ProductDisplayName
      ,AgentComment
      ,PostingType
      ,Amount
INTO #Compensationlist
FROM fct.vCompensation Comp
LEFT JOIN
dim.vSimCard sc
	ON Comp.SK_SimCard = sc.SK_SimCard
LEFT JOIN
dim.vBundle b
	ON Comp.SK_Product = b.SK_Product
LEFT JOIN
dim.vAgentComment AGC
	ON Comp.SK_AgentComment = AGC.SK_AgentComment
LEFT JOIN
dim.vPostingType PT
	ON Comp.SK_PostingType = PT.SK_PostingType

WHERE Comp.SK_Simcard <> -1

-- Creating list with service ID og Activation Date + Cancellation Date --

DROP TABLE IF EXISTS #ServiceIDList;

SELECT DISTINCT
	sub.SK_SimCard
	,ServiceID
	,SK_Date_Activation
	,SK_Date_Cancellation
INTO #ServiceIDList
FROM fct.vSubscriber Sub
LEFT JOIN 
dim.vSimCard sc
	ON Sub.SK_SimCard = sc.SK_SimCard

-- Join Activation Date and Cancellation Date on Compenstions list --

SELECT 
	#Compensationlist.SK_SimCard
	,#Compensationlist.ServiceID
	,SK_Date_Compensation
	,SK_Date_Activation
	,SK_Date_Cancellation
    ,BundleGroupLevel1
	,BundleGroupLevel2
	,BundleGroupLevel3
	,BundleDisplayName
    ,AgentComment
    ,PostingType
    ,Amount
FROM #Compensationlist
LEFT JOIN
#ServiceIDList ON #Compensationlist.SK_SimCard = #ServiceIDList.SK_SimCard

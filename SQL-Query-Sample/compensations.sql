--this script find compensations given to customers.
SELECT 
      SK_Date_Charge
      ,U.SK_TransactionType
	  ,TransactionText
      ,[SK_SimCard]
	  ,AccountType
      ,[CostWithoutVat]
      ,[VAT]
  FROM [DataMoreDPA].[fct].[vUsage] U
LEFT JOIN 
dim.vTransactionType ON U.SK_TransactionType = dim.vTransactionType.SK_TransactionType
LEFT JOIN
dim.vAccountType ON U.SK_AccountType = dim.vAccountType.SK_AccountType

WHERE 
	SK_Date_Charge >= 20220101
	AND TransactionText LIKE '%Kompensation%'

ORDER BY SK_Date_Charge ASC

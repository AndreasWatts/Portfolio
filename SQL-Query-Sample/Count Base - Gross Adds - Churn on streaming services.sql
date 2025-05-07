--This script creates a table containing the customer base, adds and churn for streaming services.

CREATE PROCEDURE [ds].[CreateStreamingBaseAddsRemoves]
AS
BEGIN

    DROP TABLE IF EXISTS #TempBase;
    SELECT CAST(SubStartDatetime AS date) AS ProductStart
         , CAST(SubEndDatetime AS date) AS ProductEnd
         , ProductName
         , COUNT(ServiceID) ServiceID
    INTO #TempBase
    FROM dbo.subscriber
	-- Andreas har tilføjet Disney og Max på liste af POer
    WHERE ProductName IN (N'NetflixBasicPlan', N'NetflixPremiumPlan', N'NetflixStandardPlan', N'Netflix', N'TV2Play', N'TV2PlayBasisPlan', N'TV2PlayBasisPlanWithAds', N'Viaplay', N'ViaplayFilmPlan', N'ViaplayFilmPlanWithAds',
						N'HBO', N'HBOMax', N'MaxBasicPlanWithAds', N'MaxStandardPlan', N'DisneyPlus', N'DisneyPlusCampaign', N'DisneyPlusPremiumPlan', N'DisneyPlusStandardPlanWithAds')
    AND   SubEndDatetime >= '2024-01-01'
    GROUP BY CAST(SubStartDatetime AS date)
           , CAST(SubEndDatetime AS date)
           , ProductName;

    DROP TABLE IF EXISTS #TempAdd;
    SELECT COUNT(DISTINCT ServiceID) Adds
         , CAST(SubStartDatetime AS date) AS SubStartDateTime
         , ProductName
    INTO #TempAdd
    FROM dbo.subscriber
	-- Andreas har tilføjet Disney og Max på liste af POer
    WHERE ProductName IN (N'NetflixBasicPlan', N'NetflixPremiumPlan', N'NetflixStandardPlan', N'Netflix', N'TV2Play', N'TV2PlayBasisPlan', N'TV2PlayBasisPlanWithAds', N'Viaplay', N'ViaplayFilmPlan', N'ViaplayFilmPlanWithAds',
						N'HBO', N'HBOMax', N'MaxBasicPlanWithAds', N'MaxStandardPlan', N'DisneyPlus', N'DisneyPlusCampaign', N'DisneyPlusPremiumPlan', N'DisneyPlusStandardPlanWithAds')
    AND   SubStartDateTime >= '2024-01-01 00:00:00.000'
    GROUP BY CAST(SubStartDateTime AS date)
           , ProductName;

    DROP TABLE IF EXISTS #TempRemove;
    SELECT COUNT(DISTINCT ServiceID) Removes
         , CAST(SubEndDatetime AS date) AS SubEndDatetime
         , ProductName
    INTO #TempRemove
    FROM dbo.subscriber
	-- Andreas har tilføjet Disney og Max på liste af POer
    WHERE POName IN (N'NetflixBasicPlan', N'NetflixPremiumPlan', N'NetflixStandardPlan', N'Netflix', N'TV2Play', N'TV2PlayBasisPlan', N'TV2PlayBasisPlanWithAds', N'Viaplay', N'ViaplayFilmPlan', N'ViaplayFilmPlanWithAds',
						N'HBO', N'HBOMax', N'MaxBasicPlanWithAds', N'MaxStandardPlan', N'DisneyPlus', N'DisneyPlusCampaign', N'DisneyPlusPremiumPlan', N'DisneyPlusStandardPlanWithAds')
    AND   SubEndDatetime >= '2024-01-01 00:00:00.000'
    GROUP BY CAST(SubEndDatetime AS date)
           , ProductName;

    DROP TABLE IF EXISTS #TempBasePerDay;
    SELECT d.Date
         , po.ProductName
         , SUM(po.ServiceID) AS Base
    INTO #TempBasePerDay
    FROM dim.vDate d
    LEFT JOIN (SELECT ProductStart, ProductEnd, ProductName, ServiceID FROM #TempBase) po
        ON  d.Date >= po.ProductStart
        AND d.Date < po.ProductEnd
    WHERE d.Date >= '2024-01-01'
    AND   d.Date < GETDATE()
    GROUP BY d.Date
           , po.ProductName;

    TRUNCATE TABLE ds.StreamingBaseAddsRemoves;
    INSERT INTO ds.StreamingBaseAddsRemoves
    (
        Date
      , TV2Play_Base
      , TV2Play_Adds
      , TV2Play_Removes
      , Viaplay_Base
      , Viaplay_Adds
      , Viaplay_Removes
      , Netflix_Base
      , Netflix_Adds
      , Netflix_Removes
	-- Andreas har tilføjet Disney og Max her:
	  , Max_Base
	  , Max_Adds
	  , Max_Removes
	  , Disney_Base
	  , Disney_Adds
	  , Disney_Removes
    )
	-- Andreas har tilføjet Disney og Max her:
    SELECT c.[Date]
         , TV2Play_Base = MAX(CASE WHEN c.ProductName = 'TV2Play' THEN c.Base
                              END)
         , TV2Play_Adds = MAX(CASE WHEN c.ProductName = 'TV2Play' THEN c.Adds
                              END)
         , TV2Play_Removes = MAX(CASE WHEN c.ProductName = 'TV2Play' THEN c.Removes
                                 END)
         , Viaplay_Base = MAX(CASE WHEN c.ProductName = 'Viaplay' THEN c.Base
                              END)
         , Viaplay_Adds = MAX(CASE WHEN c.ProductName = 'Viaplay' THEN c.Adds
                              END)
         , Viaplay_Removes = MAX(CASE WHEN c.ProductName = 'Viaplay' THEN c.Removes
                                 END)
         , Netflix_Base = MAX(CASE WHEN c.ProductName = 'Netflix' THEN c.Base
                              END)
         , Netflix_Adds = MAX(CASE WHEN c.ProductName = 'Netflix' THEN c.Adds
                              END)
         , Netflix_Removes = MAX(CASE WHEN c.ProductName = 'Netflix' THEN c.Removes
                                 END)
		 , Max_Base = MAX(CASE WHEN c.ProductName = 'HBOMax' THEN c.Base
                              END)
         , Max_Adds = MAX(CASE WHEN c.ProductName = 'HBOMax' THEN c.Adds
                              END)
         , Max_Removes = MAX(CASE WHEN c.ProductName = 'HBOMax' THEN c.Removes
                                 END)
		 , Disney_Base = MAX(CASE WHEN c.ProductName = 'DisneyPlus' THEN c.Base END) - COALESCE(MAX(CASE WHEN c.ProductName = 'DisneyPlusCampaign' THEN c.Base END), 0) --Subtracting certain campaign product
         , Disney_Adds = MAX(CASE WHEN c.ProductName = 'DisneyPlus' THEN c.Adds END) - COALESCE(MAX(CASE WHEN c.ProductName = 'DisneyPlusCampaign' THEN c.Adds END), 0)
         , Disney_Removes = MAX(CASE WHEN c.ProductName = 'DisneyPlus' THEN c.Removes END) - COALESCE(MAX(CASE WHEN c.ProductName = 'DisneyPlusCampaign' THEN c.Removes END), 0)
    FROM (   SELECT t.Date
                  , t.POName
                  , t.Base
                  , a.Adds
                  , r.Removes
             FROM #TempBasePerDay t
             LEFT JOIN #TempAdd a
                 ON  t.Date = a.SubStartDateTime
                 AND t.ProductName = a.ProductName
             LEFT JOIN #TempRemove r
                 ON  t.Date = r.SubEndDatetime
                 AND t.ProductName = r.ProductName) c
    GROUP BY c.[Date];
END;

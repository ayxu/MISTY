--after
--exec [Sales_Export_IFRS_ZY_20170601_V2] '1025','1 Jan 2016', '31 Jan 2016',1  

SELECT YearPeriod, 
    SELECT N'2016' + N'.' +  
  FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A INNER JOIN (SELECT A.RPOSCode, RPOSCodeReplacement 
 UNION ALL 
SELECT '2016' + N'.' +  
FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A INNER JOIN Companies C 
--before
--exec SperI_Export '1025','1 Jan 2016', '31 Jan 2016', 1  

SELECT YearPeriod, 
  CalendarDay, 
  DataEntryYearPeriod, 
  Version, 
  ReportingUnit, 
  UpperHierarchy, 
  PartnerReportingUnit, 
  PartnerUpperHierarchy, 
  Shares, 
  RPOSCode, 
  MovementType, 
  MaterialLocal, 
  MaterialGlobal, 
  IntlArticleGPH, 
  [Function], 
  CountryOfDestination, 
  CustomerLocal, 
  AuditID, 
  LocalCurrency, 
  REPLACE(CONVERT(NVARCHAR,LocalCurrencyAmount),N'.',N',') AS LocalCurrencyAmount, 
  TransactionCurrency, 
  TransactionCurrencyAmount, 
--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" 
/* 
  QuantityPC, 
  QuantityAltUnit, 
  QuantityLoose, 
  QuantityUnit 
*/ 
  REPLACE(CONVERT(NVARCHAR,QuantityPC),N'.',N',') AS QuantityPC, 
  REPLACE(CONVERT(NVARCHAR,QuantityAltUnit),N'.',N',') AS QuantityAltUnit, 
       CASE WHEN QuantityLoose = 0 THEN '' 
       ELSE REPLACE(CONVERT(NVARCHAR,QuantityLoose),N'.',N',') 
  END AS QuantityLoose, 
  CASE WHEN QuantityLoose = 0 THEN '' 
       ELSE REPLACE(CONVERT(NVARCHAR,QuantityUnit),N'.',N',') 
  END AS QuantityUnit 
--FSL 20111205 END 
FROM ( 
SELECT '2016' + N'.' + 
 '01' AS YearPeriod, 
 N'' AS CalendarDay, 
 N'' AS DataEntryYearPeriod, 
 A.Version, 
 A.ReportingUnit, 
 A.UpperHierarchy, 
 A.PartnerReportingUnit, 
 A.PartnerUpperHierarchy, 
 N'' AS Shares, 
 A.RPOSCode, 
 N'' AS MovementType, 
 A.MaterialLocal, 
 A.MaterialGlobal, 
 A.IntlArticleGPH, 
 N'' AS [Function], 
 A.CountryOfDestination, 
 A.CustomerLocal, 
 N'' AS AuditID, 
 A.LocalCurrency, 
 SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, 
 N'' AS TransactionCurrency, 
 N'' AS TransactionCurrencyAmount, 
 --REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N'.',N',') AS QuantityPC, 
 
--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" 
/* 
 REPLACE(CONVERT(NVARCHAR,SUM(A.QuantityPC)),N'.',N',') AS QuantityPC, 
 dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) AS QuantityAltUnit, 
 CASE WHEN SUM(A.QuantityLoose) = 0 THEN '' 
   ELSE REPLACE(CONVERT(NVARCHAR,SUM(A.QuantityLoose)),N'.',N',') 
 END AS QuantityLoose, 
*/ 
 SUM(CONVERT(NUMERIC(27,6),A.QuantityPC)) AS QuantityPC, 
 CASE WHEN  A.RPOSCode != '5811220000' THEN SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) ELSE 0 END  AS QuantityAltUnit,  
 SUM(A.QuantityLoose) AS QuantityLoose, 
--FSL 20111205 END 
 
 CASE WHEN SUM(A.QuantityLoose) = 0 THEN '' 
   ELSE A.QuantityUnit 
 END AS QuantityUnit 
FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A  INNER JOIN (SELECT A.RPOSCode, A.IsDataFromStatistics 
                                             FROM ReportingPositions A INNER JOIN (SELECT RPOSCode 
                                                                                   FROM ReportingPositions 
                                                                                   WHERE IsSperI = 1) B 
                                                    ON A.RPOSCodeReplacement = B.RPOSCode) B 
 ON A.RPOSCode = B.RPOSCode 
INNER JOIN Companies C 
 ON A.CompanyCode = C.CompanyCode 
WHERE C.CMGID = '1025' 
 AND A.InvoiceDate BETWEEN '2016/01/01' AND '2016/01/31' 
 AND ((C.IncludeInSperISTExtract = 1 AND ISNULL(B.IsDataFromStatistics,0) = 1) OR 
 (C.IncludeInSperIGLExtract = 1 AND ISNULL(B.IsDataFromStatistics,0) = 0) 
 ) 
GROUP BY
 A.Version, 
 A.ReportingUnit, 
 A.UpperHierarchy, 
 A.PartnerReportingUnit, 
 A.PartnerUpperHierarchy, 
 A.RPOSCode, 
 A.MaterialLocal, 
 A.MaterialGlobal, 
 A.IntlArticleGPH, 
 A.CountryOfDestination, 
 A.CustomerLocal, 
 A.LocalCurrency, 
 A.QuantityUnit 
   --dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) 

 UNION ALL 
select 
 P.YearPeriod, 
 N'' AS CalendarDay, 
 N'' AS DataEntryYearPeriod, 
 P.Version, 
 P.ReportingUnit, 
 P.UpperHierarchy, 
 P.PartnerReportingUnit, 
 P.PartnerUpperHierarchy, 
 N'' AS Shares, 
 P.RPOSCode, 
 N'' AS MovementType, 
 P.MaterialLocal, 
 P.MaterialGlobal, 
 P.IntlArticleGPH, 
 N'' AS [Function], 
 P.CountryOfDestination, 
 P.CustomerLocal, 
 N'' AS AuditID, 
 P.LocalCurrency,   
 SUM(CONVERT(NUMERIC(27,2),LocalCurrencyAmount)) AS LocalCurrencyAmount, 
 '' AS TransactionCurrency, 
 '' AS TransactionCurrencyAmount, 
--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" 
/* 
 REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,6),P.QuantityPC))),N'.',N',') AS QuantityPC, 
 REPLACE(CONVERT(NVARCHAR,SUM(P.QuantityAltUnit)),N'.',N',') AS QuantityAltUnit, 
 CASE WHEN SUM(P.QuantityLoose) = 0 THEN '' 
   ELSE REPLACE(CONVERT(NVARCHAR,SUM(P.QuantityLoose)),N'.',N',') 
 END AS QuantityLoose, 
 CASE WHEN SUM(P.QuantityLoose) = 0 THEN '' 
 ELSE P.QuantityUnit 
 END AS QuantityUnit 
*/ 
 SUM(CONVERT(NUMERIC(27,6),P.QuantityPC)) AS QuantityPC, 
 SUM(P.QuantityAltUnit) AS QuantityAltUnit, 
 SUM(P.QuantityLoose) AS QuantityLoose, 
 P.QuantityUnit AS QuantityUnit 
--FSL 20111205  END 
FROM  ( SELECT '2016' + N'.' + 
  '01' AS YearPeriod, 
  A.Version, 
  A.ReportingUnit, 
  A.UpperHierarchy, 
  A.PartnerReportingUnit, 
  A.PartnerUpperHierarchy, 
  B.RPOSCodeReplacement AS RPOSCode, 
  A.MaterialLocal, 
  A.MaterialGlobal, 
  A.IntlArticleGPH, 
  A.CountryOfDestination, 
  A.CustomerLocal, 
  A.LocalCurrency, 
  LocalCurrencyAmount, 
  CASE WHEN A.RPOSCode IN ('5811100000', '5811210000') 
   THEN QuantityPC 
   ELSE 0 
  END QuantityPC, 
    CASE WHEN  A.RPOSCode not in('5811220000', '5811240000') THEN dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) ELSE 0 END AS QuantityAltUnit, 
  QuantityLoose, 
--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" 
--                                      QuantityUnit 
 
     CASE WHEN QuantityLoose = 0 THEN '' 
             ELSE QuantityUnit 
        END QuantityUnit 
--FSL 20111205 END 
 FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A  INNER JOIN (SELECT RPOSCode, RPOSCodeReplacement 
                                                FROM ReportingPositions 
                                                WHERE RPOSCodeReplacement = '3011110000' 
                                                  AND IsSperI = 1) B 
  ON A.RPOSCode = B.RPOSCode 
 INNER JOIN Companies C 
  ON A.CompanyCode = C.CompanyCode 
 WHERE C.CMGID = '1025' 
  AND A.InvoiceDate BETWEEN '2016/01/01' AND '2016/01/31' 
  AND C.IncludeInSperISTExtract = 1 
 ) P 
GROUP BY P.YearPeriod, 
 P.Version, 
 P.ReportingUnit, 
 P.UpperHierarchy, 
 P.PartnerReportingUnit, 
 P.PartnerUpperHierarchy, 
 P.RPOSCode, 
 P.MaterialLocal, 
 P.MaterialGlobal, 
 P.IntlArticleGPH, 
 P.CountryOfDestination, 
 P.CustomerLocal, 
 P.LocalCurrency, 
   P.QuantityUnit  
)U 
--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" 
/* 
WHERE CAST(REPLACE(U.LocalCurrencyAmount, ',', '.') AS NUMERIC) <> 0 OR  
  CAST(REPLACE(U.QuantityPC, ',', '.') AS NUMERIC) <> 0 
*/ 
WHERE ISNULL(U.LocalCurrencyAmount,0) <> 0 OR  
  ISNULL(U.QuantityPC,0) <> 0 
ORDER BY U.RPOSCode 
--FSL 20111205 END 

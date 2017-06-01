--after
--exec [Sales_Export_IFRS_ZY_20170601_V2] '1025','1 Jan 2016', '31 Jan 2016',1  

SELECT YearPeriod,   CalendarDay,   DataEntryYearPeriod,   Version,   ReportingUnit,   UpperHierarchy,   PartnerReportingUnit,   PartnerUpperHierarchy,   Shares,   RPOSCode,   MovementType,   MaterialLocal,   MaterialGlobal,   IntlArticleGPH,   [Function],   CountryOfDestination,   CustomerLocal,   AuditID,   LocalCurrency,   REPLACE(CONVERT(NVARCHAR,SUM(LocalCurrencyAmount)),N'.',N',') AS LocalCurrencyAmount,   TransactionCurrency,   TransactionCurrencyAmount,   REPLACE(CONVERT(NVARCHAR,SUM(QuantityPC)),N'.',N',') AS QuantityPC,   REPLACE(CONVERT(NVARCHAR,(QuantityAltUnit)),N'.',N',') AS QuantityAltUnit,   QuantityLoose,   QuantityUnit,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN InvoiceNo ELSE '' END AS InvoiceNo,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CONVERT(VARCHAR,InvoiceDate,112) ELSE '' END AS InvoiceDate,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN OrderChannel ELSE '' END AS OrderChannel,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN DistributionChannel ELSE '' END AS DistributionChannel,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocalShipTo ELSE '' END AS CustomerLocalShipTo,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocal ELSE '' END AS CustomerLocalBillTo,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocal ELSE '' END AS CustomerLocalPayer,   '' AS UltimateCountryOfDestination  FROM ( 
    SELECT N'2016' + N'.' +           N'01' AS YearPeriod,      N'31' AS CalendarDay,      N'' AS DataEntryYearPeriod,      A.Version,      A.ReportingUnit,      A.UpperHierarchy,      A.PartnerReportingUnit,      A.PartnerUpperHierarchy,      A.Shares, 	 Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], '3011110000') 	      else B.RPOSCodeReplacement end AS RPOSCode,      A.MovementType,      A.MaterialLocal,      A.MaterialGlobal,      A.IntlArticleGPH,      A.[Function],      A.CountryOfDestination,      A.CustomerLocal,      A.AuditID,  A.LocalCurrency,      SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount,     N'' AS TransactionCurrency,     N'' AS TransactionCurrencyAmount,     SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC,     SUM( dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit)) AS QuantityAltUnit,   N'' AS QuantityLoose,     N'' AS QuantityUnit,      A.InvoiceDate,      A.InvoiceNo,      A.OrderChannel,      A.DistributionChannel,      A.CustomerLocalShipTo 
  FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A INNER JOIN (SELECT A.RPOSCode, RPOSCodeReplacement                              FROM ReportingPositions A INNER JOIN (SELECT RPOSCode                                       FROM ReportingPositions                                      WHERE IsDaily = 1) B                               ON A.RPOSCodeReplacement = B.RPOSCode) B       ON A.RPOSCode = B.RPOSCode   INNER JOIN Companies C    ON A.CompanyCode = C.CompanyCode   INNER JOIN ScalaHU_1025..SC019100 D	ON A.MaterialLocal = D.SC01001  LEFT OUTER JOIN SelectionCriteria E --valid date	ON A.CompanyCode = E.CompanyCode and E.[Type] = 'IFRS15'  LEFT OUTER JOIN SelectionCriteria F --RPOSCode	ON A.CompanyCode = F.CompanyCode and 'IFRS15-' + D.SC01160 = F.[Type]  WHERE C.CMGID = '1025'     AND CONVERT(DATETIME,CONVERT(NVARCHAR,A.InvoiceDate,111)) BETWEEN '2016/01/01' AND '2016/01/31'      AND C.IncludeInDailySalesExtract = 1     --AND A.QUANTITYPC != 0      --ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders    AND ISNULL(UsedScript,'') <> 'CustomerOpenOrders_Data_Extract'      --ABDUL.W 20120110 END   GROUP BY A.YearPeriod,    A.DataEntryYearPeriod,    A.Version,    A.ReportingUnit,    A.UpperHierarchy,    A.PartnerReportingUnit,    A.PartnerUpperHierarchy,    A.Shares,  Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], '3011110000') 	  else B.RPOSCodeReplacement end,    A.MovementType,    A.MaterialLocal,    A.MaterialGlobal,    A.IntlArticleGPH,    A.[Function],    A.CountryOfDestination,    A.CustomerLocal,    A.AuditID,    A.LocalCurrency,     dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit),    A.InvoiceDate,    A.InvoiceNo,    A.OrderChannel,    A.DistributionChannel,    A.CustomerLocalShipTo 
 UNION ALL 
SELECT '2016' + N'.' +       '01' AS YearPeriod,   '31' AS CalendarDay,    N'' AS DataEntryYearPeriod,   A.Version,   A.ReportingUnit,   A.UpperHierarchy,   A.PartnerReportingUnit,   A.PartnerUpperHierarchy,   A.Shares,  Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], '3011110000') 	  else A.RPOSCode end AS RPOSCode,   A.MovementType,   A.MaterialLocal,   A.MaterialGlobal,   A.IntlArticleGPH,   A.[Function],   A.CountryOfDestination,   A.CustomerLocal,   A.AuditID,   A.LocalCurrency,   SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount,     N'' AS TransactionCurrency,     N'' AS TransactionCurrencyAmount,   SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC,   SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) AS QuantityAltUnit,   N'' AS QuantityLoose,   N'' AS QuantityUnit,   A.InvoiceDate,   A.InvoiceNo,   A.OrderChannel,   A.DistributionChannel,   A.CustomerLocalShipTo  
FROM GS_DB_TBL_ATR_GaussFinanceClusterI_102516 A INNER JOIN Companies C     ON A.CompanyCode = C.CompanyCode   INNER JOIN ScalaHU_1025..SC019100 D	ON A.MaterialLocal = D.SC01001  LEFT OUTER JOIN SelectionCriteria E --valid date	ON A.CompanyCode = E.CompanyCode and E.[Type] = 'IFRS15'  LEFT OUTER JOIN SelectionCriteria F --RPOSCode	ON A.CompanyCode = F.CompanyCode and 'IFRS15-' + D.SC01160 = F.[Type]WHERE UsedScript='CustomerOpenOrders_Data_Extract'   AND C.CMGID = '1025'    --ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders   --  AND  CONVERT (datetime,A.ExtractDate,103) >= CONVERT(datetime,@ExportDateFrom,103) AND CONVERT(datetime,A.ExtractDate,103) <=convert(datetime,@ExportDateTo,103)    AND  CONVERT(DATETIME,CONVERT(NVARCHAR,A.ExtractDate,111)) BETWEEN '2016/01/01' AND '2016/01/31'   --ABDUL.W 20120110 END    AND C.IncludeInDailySalesExtract = 1    --AND A.QUANTITYPC != 0   GROUP BY   /* FSL Begin: 2010 Apr 6   --A.YearPeriod,   --A.DataEntryYearPeriod,   FSL End*/   A.Version,   A.ReportingUnit,   A.UpperHierarchy,   A.PartnerReportingUnit,   A.PartnerUpperHierarchy,   A.Shares,  Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], '3011110000') 	  else A.RPOSCode end,   A.MovementType,   A.MaterialLocal,   A.MaterialGlobal,   A.IntlArticleGPH,   A.[Function],   A.CountryOfDestination,   A.CustomerLocal,   A.AuditID,   A.LocalCurrency,   dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit),   A.InvoiceDate,   A.InvoiceNo,   A.OrderChannel,   A.DistributionChannel,   A.CustomerLocalShipTo  ) M LEFT OUTER JOIN MerckStructure N ON M.UpperHierarchy = N.DIVBFSBU  WHERE M.LocalCurrencyAmount <>0     GROUP BY         YearPeriod,   CalendarDay,   DataEntryYearPeriod,   Version,   ReportingUnit,   UpperHierarchy,   PartnerReportingUnit,   PartnerUpperHierarchy,   Shares,   RPOSCode,   MovementType,   MaterialLocal,   MaterialGlobal,   IntlArticleGPH,   [Function],   CountryOfDestination,   CustomerLocal,   AuditID,   LocalCurrency,   TransactionCurrency,   TransactionCurrencyAmount,   QuantityAltUnit,   QuantityLoose,   QuantityUnit,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN InvoiceNo ELSE '' END,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CONVERT(VARCHAR,InvoiceDate,112) ELSE '' END ,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN OrderChannel ELSE '' END,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN DistributionChannel ELSE '' END,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocalShipTo ELSE '' END,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocal ELSE '' END,   CASE WHEN N.BusinessGroup='CHEMICAL' THEN CustomerLocal ELSE '' END   Having sum(LocalCurrencyAmount) <>0  ORDER BY M.RPOSCode 

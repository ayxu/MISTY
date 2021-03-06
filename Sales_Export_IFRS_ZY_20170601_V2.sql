USE [MISTY]
GO
/****** Object:  StoredProcedure [dbo].[Sales_Export]    Script Date: 6/1/2017 5:04:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================          
-- Author:            
-- Create date:           
-- Description:           
              
-- Author:    Froilan Limuco          
-- Modified date: 20-May-2013          
-- Description:           
--    - Retrieves records from GS_DB_TBL_ATR_GaussFinanceClusterI_<CMGID><YY>.          
          
          
-- Author:    Venu Gopal          
-- Modified date: 30-Sep-2015          
-- Description:           
--    - Included Quantity PC export for new daily sales format format as well as old format (Ref: SCR_10036).          
        
        
        
-- Author :  Witney See        
-- Modified date : 1-Nov-2016        
-- Bugfix ticket : INC0170045        
-- Description:        
--  - QuantityAltUnit  should have comma as decimal separator, while  Quantity PC  should be  sum up in the  selection to tally with the sum LocalCurrencyAmount. 
--  - Sum QtyAltUnit in nested queries ( refer WSEE comments)   
--  - Add DebugMode     

-- Author :  Witney See        
-- Modified date : 9-May-2017        
-- Bugfix ticket :   INC0476834       
-- Description:        
--  - Group by QuantityPC should be commented to suppress the blank upper hierarchy issues.
--  - Comment Group by QuantityPC  ( refer WSEE comments)   
     
-- Author			: Zuoyin Xu        
-- Modified date	: 1-Jun-2017        
-- Bugfix ticket	: SCR_10066
-- Description:        
--  1. RPOSCode replacement by Revenue Classficiation condition:
--	   1) InvoiceDate >= SelectionCriteria Date (Type = IFRS15)
--	   2) SC01160 was maintained. If not, default to OLD RPOSCode
--  2. Changes to: @select1, @From1, @select2, @from2

exec Sales_Export '1042','1 Jan 2016', '31 DEC 2016',1    
================================================*/          
          
ALTER PROCEDURE [dbo].[Sales_Export_IFRS_ZY_20170601_V2]         
  @CMGID NVARCHAR(10),          
  @ExportDateFrom DATETIME,          
  @ExportDateTo DATETIME ,    
  @DebugMode bit = 0       
AS          
BEGIN          
          
          
  DECLARE @MaxExtractDate DATETIME          
  DECLARE @SELECT  NVARCHAR(4000)          
          
  DECLARE @SelectMain NVARCHAR(4000),          
          @Select1 NVARCHAR(4000),          
          @From1 NVARCHAR(4000),          
          @Select2 NVARCHAR(4000),          
          @From2 NVARCHAR(4000),          
          @ExtractDataTable NVARCHAR(255),       
          @SC01 NVARCHAR(50) --Zuoyin Xu, link to SC01 
          
  SELECT @ExtractDataTable = 'GS_DB_TBL_ATR_GaussFinanceClusterI_' +  @CMGID + RIGHT(CONVERT(NVARCHAR(4),YEAR(@ExportDateTo)),2)          
  SELECT @SC01 = DBname + '..SC01' + CompanyCode + '00' from MISTY..Companies where CMGID = @CMGID --zuoyin xu

--ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders           
  DECLARE @StartDate DATETIME          
  DECLARE @ExtractDay NUMERIC(2,0)          
  DECLARE @IsNewDailySalesFormat VARCHAR(1)          
          
  SELECT @ExtractDay = DATEPART(DAY,@ExportDateTo)          
  SELECT @StartDate =  DATEADD(DAY, (@ExtractDay * -1) + 1, @ExportDateTo)          
  SELECT @IsNewDailySalesFormat = '0'          
          
--ABDUL.W 20120110 END          
          
/*          
  SELECT @MaxExtractDate = MAX(A.ExtractDate)           
  FROM ExtractedData A INNER JOIN (SELECT A.RPOSCode, RPOSCodeReplacement          
                                   FROM ReportingPositions A INNER JOIN (SELECT RPOSCode          
                                                                         FROM ReportingPositions          
                                                                         WHERE IsDaily = 1) B          
                                          ON A.RPOSCodeReplacement = B.RPOSCode) B          
         ON A.RPOSCode = B.RPOSCode          
       INNER JOIN Companies C          
         ON A.CompanyCode = C.CompanyCode          
  WHERE C.CMGID = @CMGID           
    AND A.ExtractDate BETWEEN @ExportDateFrom AND @ExportDateTo          
    AND C.IncludeInDailySalesExtract = 1          
*/          
          
          
 SELECT @IsNewDailySalesFormat = ISNULL(B.DataValue,'0')          
 FROM Companies A LEFT OUTER JOIN SelectionCriteria B           
  ON A.CompanyCode = B.CompanyCode AND B.Type='IS_NEW_DS_FORMAT' AND B.IsIncludeRecord=1          
  WHERE A.CMGID = @CMGID           
          
 if(@IsNewDailySalesFormat='1') -- means with new 8 fields (CR-ATR_0074)          
  BEGIN          
          
            SELECT @SelectMain =           
   'SELECT YearPeriod, ' + CHAR(13) +          
   '  CalendarDay, ' + CHAR(13) +          
   '  DataEntryYearPeriod, ' + CHAR(13) +          
   '  Version, ' + CHAR(13) +     
   '  ReportingUnit, ' + CHAR(13) +          
   '  UpperHierarchy, ' + CHAR(13) +          
   '  PartnerReportingUnit, ' + CHAR(13) +          
   '  PartnerUpperHierarchy, ' + CHAR(13) +          
   '  Shares, ' + CHAR(13) +             '  RPOSCode, ' + CHAR(13) +          
   '  MovementType, ' + CHAR(13) +          
   '  MaterialLocal, ' + CHAR(13) +          
   '  MaterialGlobal, ' + CHAR(13) +          
   '  IntlArticleGPH, ' + CHAR(13) +          
   '  [Function], ' + CHAR(13) +          
   '  CountryOfDestination, ' + CHAR(13) +          
   '  CustomerLocal, ' + CHAR(13) +          
   '  AuditID, ' + CHAR(13) +          
   '  LocalCurrency, ' + CHAR(13) +          
   '  REPLACE(CONVERT(NVARCHAR,SUM(LocalCurrencyAmount)),N''.'',N'','') AS LocalCurrencyAmount, ' + CHAR(13) +          
   '  TransactionCurrency, ' + CHAR(13) +          
   '  TransactionCurrencyAmount, ' + CHAR(13) +          
/* 2016-Nov-1 WSEE  REPLACE THIS         
        
/*   2015-SEP-30 BEGIN   */          
--   '  QuantityPC, ' + CHAR(13) +          
   '  REPLACE(CONVERT(NVARCHAR,QuantityPC),N''.'',N'','') AS QuantityPC,  ' + CHAR(13) +          
/*   2015-SEP-30 END   */          
   '  QuantityAltUnit, ' + CHAR(13) +          
  REPLACE THIS END*/         
  /* 2016-Nov-1 WSEE TO THIS */        
   '  REPLACE(CONVERT(NVARCHAR,SUM(QuantityPC)),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +         
   '  REPLACE(CONVERT(NVARCHAR,(QuantityAltUnit)),N''.'',N'','') AS QuantityAltUnit, ' + CHAR(13) +         
 /*2016-Nov-1 WSEE END*/        
   '  QuantityLoose, ' + CHAR(13) +          
   '  QuantityUnit, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN InvoiceNo ELSE '''' END AS InvoiceNo, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CONVERT(VARCHAR,InvoiceDate,112) ELSE '''' END AS InvoiceDate, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN OrderChannel ELSE '''' END AS OrderChannel, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN DistributionChannel ELSE '''' END AS DistributionChannel, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocalShipTo ELSE '''' END AS CustomerLocalShipTo, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocal ELSE '''' END AS CustomerLocalBillTo, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocal ELSE '''' END AS CustomerLocalPayer, ' + CHAR(13) +          
   '  '''' AS UltimateCountryOfDestination  ' + CHAR(13) +          
   'FROM ( ' + CHAR(13)           
          
                      
            SELECT @Select1 =           
   '    SELECT N''' + CONVERT(NVARCHAR(4), YEAR(@ExportDateTo)) + ''' + N''.'' +  ' + CHAR(13) +          
   '         N''' + RIGHT('00' + CONVERT(NVARCHAR(2), MONTH(@ExportDateTo)),2) + ''' AS YearPeriod, ' + CHAR(13) +          
   '     N''' + RIGHT('00' + CONVERT(NVARCHAR(2), DAY(@ExportDateTo)),2) + ''' AS CalendarDay, ' + CHAR(13) +                   
   '     N'''' AS DataEntryYearPeriod, ' + CHAR(13) +          
   '     A.Version, ' + CHAR(13) +          
   '     A.ReportingUnit, ' + CHAR(13) +          
   '     A.UpperHierarchy, ' + CHAR(13) +          
   '     A.PartnerReportingUnit, ' + CHAR(13) +          
   '     A.PartnerUpperHierarchy, ' + CHAR(13) +          
   '     A.Shares, ' + CHAR(13) +            
   /* IFRS, Zuoyin Xu 01-June-2017. Change RPOSCode logic */         
   --original '  B.RPOSCodeReplacement AS RPOSCode, ' + CHAR(13) +           
   '	 Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	      else B.RPOSCodeReplacement end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */           
   '     A.MovementType, ' + CHAR(13) +          
   '     A.MaterialLocal, ' + CHAR(13) +          
   '     A.MaterialGlobal, ' + CHAR(13) +          
   '     A.IntlArticleGPH, ' + CHAR(13) +          
   '     A.[Function], ' + CHAR(13) +          
   '     A.CountryOfDestination, ' + CHAR(13) +          
   '     A.CustomerLocal, ' + CHAR(13) +          
   '     A.AuditID, ' + CHAR(13) +          
   ' A.LocalCurrency, ' + CHAR(13) +          
   '     SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +          
   '    N'''' AS TransactionCurrency, ' + CHAR(13) +          
   '    N'''' AS TransactionCurrencyAmount, ' + CHAR(13) +          
/*2016-NOV-1 WSEE Replace THIS         
/*   2015-SEP-30 BEGIN   */          
--   ' N'''' AS QuantityPC, ' + CHAR(13) +          
     '    REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +           
/*   2015-SEP-30 EBD   */         
     '     dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +          
        
REPLACE THIS END*/         
/* 2016-NOV-1 WSEE TO THIS */        
   '    SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC, ' + CHAR(13) +          
   '    SUM( dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit)) AS QuantityAltUnit, ' + CHAR(13) +         
/* 2016-NOV-1 WSEE END */         
   '  N'''' AS QuantityLoose, ' + CHAR(13) +          
   '    N'''' AS QuantityUnit, ' + CHAR(13) +          
   '     A.InvoiceDate, ' + CHAR(13) +          
   '     A.InvoiceNo, ' + CHAR(13) +          
   '     A.OrderChannel, ' + CHAR(13) +          
   '     A.DistributionChannel, ' + CHAR(13) +          
   '     A.CustomerLocalShipTo ' + CHAR(13)          
              
         SELECT @From1 =              
   '  FROM ' + @ExtractDataTable + ' A INNER JOIN (SELECT A.RPOSCode, RPOSCodeReplacement ' + CHAR(13) +          
   '                             FROM ReportingPositions A INNER JOIN (SELECT RPOSCode ' + CHAR(13) +          
   '                                      FROM ReportingPositions ' + CHAR(13) +          
   '                                     WHERE IsDaily = 1) B ' + CHAR(13) +          
   '                              ON A.RPOSCodeReplacement = B.RPOSCode) B ' + CHAR(13) +          
   '      ON A.RPOSCode = B.RPOSCode ' + CHAR(13) +          
   '  INNER JOIN Companies C ' + CHAR(13) +          
   '   ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +       
   /* IFRS, Zuoyin Xu 01-June-2017 */
   '  INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +   '  LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +   '  LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */      
   '  WHERE C.CMGID = ''' + @CMGID + ''' ' + CHAR(13) +           
   '    AND CONVERT(DATETIME,CONVERT(NVARCHAR,A.InvoiceDate,111)) BETWEEN ''' + CONVERT(NVARCHAR,@ExportDateFrom,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +          
         '     AND C.IncludeInDailySalesExtract = 1 ' + CHAR(13) +          
   '    --AND A.QUANTITYPC != 0 ' + CHAR(13) +          
      '     --ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders ' + CHAR(13) +           
   '   AND ISNULL(UsedScript,'''') <> ''CustomerOpenOrders_Data_Extract'' ' + CHAR(13) +          
      '     --ABDUL.W 20120110 END ' + CHAR(13) +          
   '  GROUP BY A.YearPeriod, ' + CHAR(13) +          
   '   A.DataEntryYearPeriod, ' + CHAR(13) +          
   '   A.Version, ' + CHAR(13) +          
   '   A.ReportingUnit, ' + CHAR(13) +          
   '   A.UpperHierarchy, ' + CHAR(13) +          
   '   A.PartnerReportingUnit, ' + CHAR(13) +          
   '   A.PartnerUpperHierarchy, ' + CHAR(13) +          
   '   A.Shares, ' + CHAR(13) +                 
   /* IFRS, Zuoyin Xu */
   --original '   B.RPOSCodeReplacement, ' + CHAR(13) +   
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else B.RPOSCodeReplacement end, ' + CHAR(13) +        
   /* IFRS, Zuoyin Xu */     
   '   A.MovementType, ' + CHAR(13) +          
   '   A.MaterialLocal, ' + CHAR(13) +          
   '   A.MaterialGlobal, ' + CHAR(13) +          
   '   A.IntlArticleGPH, ' + CHAR(13) +          
   '   A.[Function], ' + CHAR(13) +          
   '   A.CountryOfDestination, ' + CHAR(13) +          
   '   A.CustomerLocal, ' + CHAR(13) +          
   '   A.AuditID, ' + CHAR(13) +          
   '   A.LocalCurrency,  ' + CHAR(13) +          
   '   dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit), ' + CHAR(13) +   
   '   A.InvoiceDate, ' + CHAR(13) +          
   '   A.InvoiceNo, ' + CHAR(13) +          
   '   A.OrderChannel, ' + CHAR(13) +          
   '   A.DistributionChannel, ' + CHAR(13) +          
   '   A.CustomerLocalShipTo ' + CHAR(13)           
          
             
                   
            SELECT @Select2 =           
   'SELECT ''' + CONVERT(NVARCHAR(4), YEAR(@ExportDateTo)) + ''' + N''.'' +  ' + CHAR(13) +          
   '     ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), MONTH(@ExportDateTo)),2) + ''' AS YearPeriod, ' + CHAR(13) +                   
   '  ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), DAY(@ExportDateTo)),2) + ''' AS CalendarDay, ' + CHAR(13) +                   
   '   N'''' AS DataEntryYearPeriod, ' + CHAR(13) +          
   '  A.Version, ' + CHAR(13) +          
   '  A.ReportingUnit, ' + CHAR(13) +          
   '  A.UpperHierarchy, ' + CHAR(13) +          
   '  A.PartnerReportingUnit, ' + CHAR(13) +          
   '  A.PartnerUpperHierarchy, ' + CHAR(13) +          
   '  A.Shares, ' + CHAR(13) +              
   /* IFRS, Zuoyin Xu 01-June-2017. Change RPOSCode logic */         
   --Original ' A.RPOSCode, ' + CHAR(13) +         
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else A.RPOSCode end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */         
   '  A.MovementType, ' + CHAR(13) +          
   '  A.MaterialLocal, ' + CHAR(13) +          
   '  A.MaterialGlobal, ' + CHAR(13) +          
   '  A.IntlArticleGPH, ' + CHAR(13) +          
   '  A.[Function], ' + CHAR(13) +          
   '  A.CountryOfDestination, ' + CHAR(13) +          
   '  A.CustomerLocal, ' + CHAR(13) +          
   '  A.AuditID, ' + CHAR(13) +          
   '  A.LocalCurrency, ' + CHAR(13) +          
   '  SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +          
   '    N'''' AS TransactionCurrency, ' + CHAR(13) +          
   '    N'''' AS TransactionCurrencyAmount, ' + CHAR(13) +          
   /* 2016-NOV-1 WSEE REPLACE THIS         
   '  REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +           
   '  dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +          
   REPLACE THIS END*/        
   /*2016-NOV-1 WSEE TO THIS */        
   '  SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC, ' + CHAR(13) +           
   '  SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) AS QuantityAltUnit, ' + CHAR(13) +          
   /*2016-NOV-1 WSEE END */        
   '  N'''' AS QuantityLoose, ' + CHAR(13) +          
   '  N'''' AS QuantityUnit, ' + CHAR(13) +          
   '  A.InvoiceDate, ' + CHAR(13) +          
   '  A.InvoiceNo, ' + CHAR(13) +          
   '  A.OrderChannel, ' + CHAR(13) +          
   '  A.DistributionChannel, ' + CHAR(13) +          
   '  A.CustomerLocalShipTo  ' + CHAR(13)          
          
            SELECT @From2 =           
   'FROM ' + @ExtractDataTable + ' A INNER JOIN Companies C ' + CHAR(13) +          
   '    ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +  
   /* IFRS, Zuoyin Xu 01-June-2017 */
   '  INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +   '  LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +   '  LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */           
   'WHERE UsedScript=''CustomerOpenOrders_Data_Extract'' ' + CHAR(13) +          
   '  AND C.CMGID = ''' + @CMGID + '''  ' + CHAR(13) +          
   '  --ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders ' + CHAR(13) +           
   '  --  AND  CONVERT (datetime,A.ExtractDate,103) >= CONVERT(datetime,@ExportDateFrom,103) AND CONVERT(datetime,A.ExtractDate,103) <=convert(datetime,@ExportDateTo,103) ' + CHAR(13) +                    
   '   AND  CONVERT(DATETIME,CONVERT(NVARCHAR,A.ExtractDate,111)) BETWEEN ''' + CONVERT(NVARCHAR,@StartDate,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +          
   '  --ABDUL.W 20120110 END ' + CHAR(13) +          
   '   AND C.IncludeInDailySalesExtract = 1 ' + CHAR(13) +          
   '   --AND A.QUANTITYPC != 0 ' + CHAR(13) +          
   '  GROUP BY ' + CHAR(13) +           
   '  /* FSL Begin: 2010 Apr 6 ' + CHAR(13) +          
   '  --A.YearPeriod, ' + CHAR(13) +          
   '  --A.DataEntryYearPeriod, ' + CHAR(13) +          
   '  FSL End*/ ' + CHAR(13) +     '  A.Version, ' + CHAR(13) +          
   '  A.ReportingUnit, ' + CHAR(13) +          
   '  A.UpperHierarchy, ' + CHAR(13) +          
   '  A.PartnerReportingUnit, ' + CHAR(13) +          
   '  A.PartnerUpperHierarchy, ' + CHAR(13) +          
   '  A.Shares, ' + CHAR(13) +          
   /* IFRS, Zuoyin Xu */
   --original '  A.RPOSCode, ' + CHAR(13) +     
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else A.RPOSCode end, ' + CHAR(13) +        
   /* IFRS, Zuoyin Xu */
   '  A.MovementType, ' + CHAR(13) +          
   '  A.MaterialLocal, ' + CHAR(13) +          
   '  A.MaterialGlobal, ' + CHAR(13) +          
   '  A.IntlArticleGPH, ' + CHAR(13) +          
   '  A.[Function], ' + CHAR(13) +          
   '  A.CountryOfDestination, ' + CHAR(13) +          
   '  A.CustomerLocal, ' + CHAR(13) +          
   '  A.AuditID, ' + CHAR(13) +          
   '  A.LocalCurrency, ' + CHAR(13) +          
   '  dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit), ' + CHAR(13) +          
   '  A.InvoiceDate, ' + CHAR(13) +          
   '  A.InvoiceNo, ' + CHAR(13) +          
   '  A.OrderChannel, ' + CHAR(13) +          
   '  A.DistributionChannel, ' + CHAR(13) +          
   '  A.CustomerLocalShipTo ' + CHAR(13) +           
   ' ) M LEFT OUTER JOIN MerckStructure N ON M.UpperHierarchy = N.DIVBFSBU ' + CHAR(13) +          
   ' WHERE M.LocalCurrencyAmount <>0 ' + CHAR(13) +          
            '    GROUP BY ' + CHAR(13) +          
            '        YearPeriod, ' + CHAR(13) +          
   '  CalendarDay, ' + CHAR(13) +                   
   '  DataEntryYearPeriod, ' + CHAR(13) +          
   '  Version, ' + CHAR(13) +          
   '  ReportingUnit, ' + CHAR(13) +          
   '  UpperHierarchy, ' + CHAR(13) +          
   '  PartnerReportingUnit, ' + CHAR(13) +          
   '  PartnerUpperHierarchy, ' + CHAR(13) +          
   '  Shares, ' + CHAR(13) +          
   '  RPOSCode, ' + CHAR(13) +          
   '  MovementType, ' + CHAR(13) +          
   '  MaterialLocal, ' + CHAR(13) +          
   '  MaterialGlobal, ' + CHAR(13) +          
   '  IntlArticleGPH, ' + CHAR(13) +          
   '  [Function], ' + CHAR(13) +          
   '  CountryOfDestination, ' + CHAR(13) +          
   '  CustomerLocal, ' + CHAR(13) +          
   '  AuditID, ' + CHAR(13) +          
   '  LocalCurrency, ' + CHAR(13) +          
   '  TransactionCurrency, ' + CHAR(13) +          
   '  TransactionCurrencyAmount, ' + CHAR(13) +          
  /**  2017-May-9  WSEE  
   '  QuantityPC,  ' + CHAR(13) +    
   **/      
   '  QuantityAltUnit, ' + CHAR(13) +          
   '  QuantityLoose, ' + CHAR(13) +          
   '  QuantityUnit, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN InvoiceNo ELSE '''' END, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CONVERT(VARCHAR,InvoiceDate,112) ELSE '''' END , ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN OrderChannel ELSE '''' END, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN DistributionChannel ELSE '''' END, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocalShipTo ELSE '''' END, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocal ELSE '''' END, ' + CHAR(13) +          
   '  CASE WHEN N.BusinessGroup=''CHEMICAL'' THEN CustomerLocal ELSE '''' END ' + CHAR(13) +  
    /**  2017-May-9  WSEE  BEGIN **/
	'  Having sum(LocalCurrencyAmount) <>0 ' + CHAR(13) +
	/** 2017-May-9 END **/
           
   ' ORDER BY M.RPOSCode ' + CHAR(13)           
          
/* GLOSS PERFORMANCE TESTING          
   EXEC ('TRUNCATE TABLE GAUSS_OUTPUT ' +          
                  'INSERT INTO GAUSS_OUTPUT ' +             
                  @SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2 )          
*/          
       
       
       
      IF @DebugMode = 1           
 BEGIN          
      PRINT @SelectMain 
	  PRINT @Select1 
	  PRINT @From1
      PRINT ' UNION ALL '         
      PRINT @Select2 
	  PRINT @From2
 END          
 ELSE          
 BEGIN            
          
 EXEC (@SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2 )        
            
 END          
END        
                     
                    
                
          
         
 ELSE          
  BEGIN          
          
            SELECT @SelectMain =          
   'SELECT YearPeriod, ' + CHAR(13) +           
   '       CalendarDay, ' + CHAR(13) +                    
   '       DataEntryYearPeriod, ' + CHAR(13) +           
   '       Version, ' + CHAR(13) +           
   '       ReportingUnit, ' + CHAR(13) +           
   '       UpperHierarchy, ' + CHAR(13) +           
   '       PartnerReportingUnit, ' + CHAR(13) +           
   '  PartnerUpperHierarchy, ' + CHAR(13) +           
   '       Shares, ' + CHAR(13) +           
   '       RPOSCode, ' + CHAR(13) +           
   '       MovementType, ' + CHAR(13) +           
   '       MaterialLocal, ' + CHAR(13) +           
   '       MaterialGlobal, ' + CHAR(13) +           
   '       IntlArticleGPH, ' + CHAR(13) +           
   '       [Function], ' + CHAR(13) +           
   '       CountryOfDestination, ' + CHAR(13) +           
   '       CustomerLocal, ' + CHAR(13) +           
   '       AuditID, ' + CHAR(13) +           
   '       LocalCurrency, ' + CHAR(13) +           
   '       REPLACE(CONVERT(NVARCHAR,LocalCurrencyAmount),N''.'',N'','') AS LocalCurrencyAmount, ' + CHAR(13) +           
   '       TransactionCurrency, ' + CHAR(13) +       
   '       TransactionCurrencyAmount, ' + CHAR(13) +           
        
/*   2015-SEP-30 BEGIN   */          
--   '  QuantityPC, ' + CHAR(13) +           
   '       REPLACE(CONVERT(NVARCHAR,QuantityPC),N''.'',N'','') AS QuantityPC,  ' + CHAR(13) +           
/*   2015-SEP-30 END   */         
--NO SUM UP         
 /* 2016-NOV-1 WSEE REPLACE THIS         
   '       QuantityAltUnit, ' + CHAR(13) +          
     REPLACE THIS END*/        
      /*2016-NOV-1 WSEE TO THIS */        
      '       REPLACE(CONVERT(NVARCHAR,QuantityAltUnit),N''.'',N'','') AS QuantityAltUnit,  ' + CHAR(13) +           
      /*2016-NOV-1 WSEE END */         
   '       QuantityLoose, ' + CHAR(13) +           
   '       QuantityUnit ' + CHAR(13) +           
          
/* GLOSS PERFORMANCE TESTING          
            ' ,'''','''','''','''','''','''','''','''' ' +          
*/          
          
          
         'FROM ( ' + CHAR(13)           
          
            SELECT @Select1 =           
   'SELECT ''' + CONVERT(NVARCHAR(4), YEAR(@ExportDateTo)) + ''' + N''.'' + ' + CHAR(13) +            
   '     ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), DATEPART(MONTH,@ExportDateTo)),2) + ''' AS YearPeriod, ' + CHAR(13) +                     
   ' --RIGHT(N''00'' + CONVERT(NVARCHAR(2), DATEPART(DAY,@MaxExtractDate)),2) AS CalendarDay, ' + CHAR(13) +                    
   ' ' + RIGHT(N'00' + CONVERT(NVARCHAR(2), DAY(@ExportDateTo)),2) + ' AS CalendarDay, ' + CHAR(13) +                    
   ' N'''' AS DataEntryYearPeriod, ' + CHAR(13) +           
   ' A.Version, ' + CHAR(13) +           
   ' A.ReportingUnit, ' + CHAR(13) +           
   ' A.UpperHierarchy, ' + CHAR(13) +           
   ' A.PartnerReportingUnit, ' + CHAR(13) +           
   ' A.PartnerUpperHierarchy, ' + CHAR(13) +           
   ' A.Shares, ' + CHAR(13) +           
   --' B.RPOSCodeReplacement AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017. Change RPOSCode logic */         
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '      else B.RPOSCodeReplacement end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */                      
   ' A.MovementType, ' + CHAR(13) +           
   ' A.MaterialLocal, ' + CHAR(13) +           
   ' A.MaterialGlobal, ' + CHAR(13) +           
   ' A.IntlArticleGPH, ' + CHAR(13) +           
   ' A.[Function], ' + CHAR(13) +           
   ' A.CountryOfDestination, ' + CHAR(13) +           
   ' A.CustomerLocal, ' + CHAR(13) +           
   ' A.AuditID, ' + CHAR(13) +           
   ' A.LocalCurrency, ' + CHAR(13) +           
   ' SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +           
   ' N'''' AS TransactionCurrency, ' + CHAR(13) +           
   ' N'''' AS TransactionCurrencyAmount, ' + CHAR(13) +           
/* 2016-NOV-1 WSEE REPLACE THIS         
/*   2015-SEP-30 BEGIN   */          
--   ' N'''' AS QuantityPC,  ' + CHAR(13) +           
   ' REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N''.'',N'','') AS QuantityPC,  ' + CHAR(13) +           
/*   2015-SEP-30 END   */          
        
        
   ' dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +           
  REPLACE THIS END*/        
        
 /*2016-NOV-1 WSEE TO THIS */        
   '  SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC, ' + CHAR(13) +           
   '  SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) AS QuantityAltUnit, ' + CHAR(13) +          
   /*2016-NOV-1 WSEE END */        
   ' N'''' AS QuantityLoose, ' + CHAR(13) +           
   ' N'''' AS QuantityUnit ' + CHAR(13)          
          
          
            SELECT @From1 =             
   'FROM ' + @ExtractDataTable + ' A INNER JOIN (SELECT A.RPOSCode, RPOSCodeReplacement ' + CHAR(13) +           
   '                            FROM ReportingPositions A INNER JOIN (SELECT RPOSCode ' + CHAR(13) +           
   '                                    FROM ReportingPositions ' + CHAR(13) +           
   '                                    WHERE IsDaily = 1) B ' + CHAR(13) +           
   '                             ON A.RPOSCodeReplacement = B.RPOSCode) B ' + CHAR(13) +           
   '     ON A.RPOSCode = B.RPOSCode ' + CHAR(13) +           
   'INNER JOIN Companies C ' + CHAR(13) +           
   '	ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +     
   /* IFRS, Zuoyin Xu 01-June-2017 */
   'INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +   'LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +   'LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */             
   'WHERE C.CMGID = ''' + @CMGID + '''  ' + CHAR(13) +           
   ' --AND A.ExtractDate BETWEEN @ExportDateFrom AND @ExportDateTo ' + CHAR(13) +           
   ' AND CONVERT(DATETIME,CONVERT(NVARCHAR,A.InvoiceDate,111)) BETWEEN ''' + CONVERT(NVARCHAR,@ExportDateFrom,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +                               
         '  AND C.IncludeInDailySalesExtract = 1 ' + CHAR(13) +           
   ' --AND A.QUANTITYPC != 0 ' + CHAR(13) +           
            '   --ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders ' + CHAR(13) +            
            '   AND ISNULL(UsedScript,'''') <> ''CustomerOpenOrders_Data_Extract'' ' + CHAR(13) +           
            '   --ABDUL.W 20120110 END ' + CHAR(13) +           
   'GROUP BY A.YearPeriod, ' + CHAR(13) +           
   '       A.DataEntryYearPeriod, ' + CHAR(13) +           
   '       A.Version, ' + CHAR(13) +           
   '       A.ReportingUnit, ' + CHAR(13) +           
   '       A.UpperHierarchy, ' + CHAR(13) +           
   '       A.PartnerReportingUnit, ' + CHAR(13) +           
   '       A.PartnerUpperHierarchy, ' + CHAR(13) +           
   '       A.Shares, ' + CHAR(13) +           
   --'     B.RPOSCodeReplacement, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu */   
   '	  Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '		   else B.RPOSCodeReplacement end, ' + CHAR(13) +        
   /* IFRS, Zuoyin Xu */            
   '       A.MovementType, ' + CHAR(13) +           
   '       A.MaterialLocal, ' + CHAR(13) +           
   '       A.MaterialGlobal, ' + CHAR(13) +           
   '       A.IntlArticleGPH, ' + CHAR(13) +           
   '       A.[Function], ' + CHAR(13) +           
   '       A.CountryOfDestination, ' + CHAR(13) +           
   '       A.CustomerLocal, ' + CHAR(13) +           
   '       A.AuditID, ' + CHAR(13) +           
   '       A.LocalCurrency,  ' + CHAR(13) +           
   ' dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) ' + CHAR(13)               
           
          
          
   SELECT @Select2 =          
   'SELECT ''' + CONVERT(NVARCHAR(4), YEAR(@ExportDateTo)) + ''' + N''.'' + ' + CHAR(13) +          
   '     ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), MONTH(@ExportDateTo)),2) + ''' AS YearPeriod, ' + CHAR(13) +                    
   '     ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), DAY(@ExportDateTo)),2) + ''' AS CalendarDay, ' + CHAR(13) +                    
   '   N'''' AS DataEntryYearPeriod, ' + CHAR(13) +           
   '     A.Version, ' + CHAR(13) +           
   '     A.ReportingUnit, ' + CHAR(13) +           
   '     A.UpperHierarchy, ' + CHAR(13) +           
   '     A.PartnerReportingUnit, ' + CHAR(13) +           
   '     A.PartnerUpperHierarchy, ' + CHAR(13) +           
   '     A.Shares, ' + CHAR(13) +           
   --'     A.RPOSCode, ' + CHAR(13) +   
   /* IFRS - part 4, Zuoyin Xu 01-June-2017. Change RPOSCode logic */            
   '	 Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '		  else A.RPOSCode end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */             
   '     A.MovementType, ' + CHAR(13) +           
   '     A.MaterialLocal, ' + CHAR(13) +           
   '     A.MaterialGlobal, ' + CHAR(13) +           
   '     A.IntlArticleGPH, ' + CHAR(13) +           
   '     A.[Function], ' + CHAR(13) +           
   '     A.CountryOfDestination, ' + CHAR(13) +      
   '     A.CustomerLocal, ' + CHAR(13) +           
   '     A.AuditID, ' + CHAR(13) +           
   '     A.LocalCurrency, ' + CHAR(13) +           
        
   '     SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +           
   '    N'''' AS TransactionCurrency, ' + CHAR(13) +           
   '    N'''' AS TransactionCurrencyAmount, ' + CHAR(13) +           
        
/* 2016-NOV-1 WSEE REPLACE THIS         
   '     REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N''.'',N'','') AS QuantityPC,  ' + CHAR(13) +           
   '     dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +           
 REPLACE THIS END*/        
        
 /*2016-NOV-1 WSEE TO THIS */        
   '  SUM(CONVERT(NUMERIC(27,2),A.QuantityPC)) AS QuantityPC, ' + CHAR(13) +           
   '  SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) AS QuantityAltUnit, ' + CHAR(13) +          
  /*2016-NOV-1 WSEE END */        
        
   '    N'''' AS QuantityLoose, ' + CHAR(13) +           
   '    N'''' AS QuantityUnit  ' + CHAR(13) +           
   'FROM ' + @ExtractDataTable + ' A INNER JOIN Companies C ' + CHAR(13) +           
   '    ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +       
   /* IFRS - part 4, Zuoyin Xu 01-June-2017 */
   'INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +   'LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +   'LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */      
   'WHERE UsedScript=''CustomerOpenOrders_Data_Extract'' ' + CHAR(13) +           
   '  AND C.CMGID = ''' + @CMGID + ''' ' + CHAR(13) +            
            '--ABDUL.W 20120110 BEGIN Correction on export getting previous months Open Orders ' + CHAR(13) +            
            '--  AND  CONVERT (datetime,A.ExtractDate,103) >= CONVERT(datetime,@ExportDateFrom,103) AND CONVERT(datetime,A.ExtractDate,103) <=convert(datetime,@ExportDateTo,103) ' + CHAR(13) +                     
   '  AND  CONVERT(DATETIME,CONVERT(NVARCHAR,A.ExtractDate,111)) BETWEEN ''' + CONVERT(NVARCHAR,@StartDate,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +           
            '--ABDUL.W 20120110 END ' + CHAR(13) +           
   '  AND C.IncludeInDailySalesExtract = 1 ' + CHAR(13) +           
   '--AND A.QUANTITYPC != 0 ' + CHAR(13) +           
   'GROUP BY ' + CHAR(13) +            
   '/* FSL Begin: 2010 Apr 6 ' + CHAR(13) +           
   '--A.YearPeriod, ' + CHAR(13) +           
   '--A.DataEntryYearPeriod, ' + CHAR(13) +           
   'FSL End*/ ' + CHAR(13) +           
   'A.Version, ' + CHAR(13) +           
   'A.ReportingUnit, ' + CHAR(13) +           
   'A.UpperHierarchy, ' + CHAR(13) +           
   'A.PartnerReportingUnit, ' + CHAR(13) +           
   'A.PartnerUpperHierarchy, ' + CHAR(13) +           
   'A.Shares, ' + CHAR(13) +           
   --'A.RPOSCode, ' + CHAR(13) +      
   /* IFRS - 2nd section2, Zuoyin Xu */   
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else A.RPOSCode end, ' + CHAR(13) +        
   /* IFRS, Zuoyin Xu */        
   'A.MovementType, ' + CHAR(13) +           
   'A.MaterialLocal, ' + CHAR(13) +           
  'A.MaterialGlobal, ' + CHAR(13) +           
   'A.IntlArticleGPH, ' + CHAR(13) +           
   'A.[Function], ' + CHAR(13) +           
   'A.CountryOfDestination, ' + CHAR(13) +           
   'A.CustomerLocal, ' + CHAR(13) +           
   'A.AuditID, ' + CHAR(13) +           
   'A.LocalCurrency,  ' + CHAR(13) +           
      'dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) ' + CHAR(13) +          
  ') M ' + CHAR(13) +            
  'WHERE M.LocalCurrencyAmount <>0 ' + CHAR(13) +           
  'ORDER BY M.RPOSCode '          
          
/* GLOSS PERFORMANCE TESTING          
   EXEC ('TRUNCATE TABLE GAUSS_OUTPUT ' +          
                  'INSERT INTO GAUSS_OUTPUT ' +             
                  @SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2 )          
*/          
          
          
           IF @DebugMode = 1           
 BEGIN          
      PRINT (@SelectMain + @Select1 + @From1)        
            PRINT ' UNION ALL '         
            PRINT ( @Select2 + @From2 )          
 END          
 ELSE          
 BEGIN            
          
 EXEC (@SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2 )        
            
 END          
        
                
          
          
 END          
          
END          
          
          
          
--Sales_5811100000_Extract          
--========================          
set ANSI_NULLS ON          
set QUOTED_IDENTIFIER ON 
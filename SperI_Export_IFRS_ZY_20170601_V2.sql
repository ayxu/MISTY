USE [MISTY]
GO
/****** Object:  StoredProcedure [dbo].[SperI_Export_IFRS_ZY_20170601_V2]    Script Date: 6/1/2017 7:52:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
         
/* =============================================            
-- Author:   ?????            
-- Modified date: ??? ??, ???2010            
-- Description:             
    - ????            
-- Author:  Verga, Ian Jamoralin, CSC-A (Scala)            
-- Modified date: Jun 30, 2010            
-- Description:             
--    - Filter for Quantity totals should also exclude those with 0 quantity.            
--             
-- Modified by:  Limuco, Froilan, CSC-A (Scala)            
-- Modified Date: 05 Dec 2011            
-- Description  Corrected the issue "Error converting data type nvarchar to numeric"            
            
-- Modified by:  Todorov, Savel, 2nd Level Scala            
-- Modified Date: 27 Jul 2012            
-- Description  Remove from grouping the A.QuantityUnit and dbo.GS_DB_FUN_CheckNeedAltQtyUnit            
            
-- Author:    Froilan Limuco            
-- Modified date: 20-May-2013            
-- Description:             
--    - Retrieves records from GS_DB_TBL_ATR_GaussFinanceClusterI_<CMGID><YY>.            
          
--Author: witney See, 2nd Level Scala          
--Modified Date: 03 May 2016          
--Description: IM5562254          
--  -add selection filter for QuantityAltUnit , if RPOSCODE = 5811220000, QuantityAltUnit = 0.           
--  add'5811240000' to the case when, see comment  WSEE    
  
--Author: witney See, 2nd Level Scala          
--Modified Date: 14 July 2016          
--Description: IM5562254 QtyAltUnit          
--  -add new selection filter for QuantityAltUnit , if RPOSCODE = 5811240000, QuantityAltUnit = 0 at the second part of RPOSCODEREPLAMENT script.           
--  remove  '5811240000' from the case when in  that was added in May2016 , see comment  WSEE    
            
-- Author :  Witney See        
-- Modified date : 9-May-2017        
-- Bugfix ticket :   INC0476900       
-- Description:        
--  - Group by by Year Period need to be removed in the nested queries to suppress the blank upper hierarchy issues.
--  - Comment Group by Year Period in nested queries ( refer WSEE comments)   
--  - Add Debugmode


exec SperI_Export '1042','1 Jan 2016', '31 DEC 2016',1  
============================================= */            
            
ALTER PROCEDURE [dbo].[SperI_Export_IFRS_ZY_20170601_V2]            
  @CMGID NVARCHAR(10),            
  @ExportDateFrom DATETIME,            
  @ExportDateTo DATETIME ,
   @DebugMode bit = 0              
AS            
BEGIN            
            
  DECLARE @MaxExtractDate DATETIME            
            
  DECLARE @sSQL NVARCHAR(4000),            
          @SelectMain NVARCHAR(4000),            
          @Select1 NVARCHAR(4000),            
          @From1 NVARCHAR(4000),            
          @Select2 NVARCHAR(4000),            
          @From2 NVARCHAR(4000),            
          @ExtractDataTable NVARCHAR(255)            
            
            
  SELECT @ExtractDataTable = 'GS_DB_TBL_ATR_GaussFinanceClusterI_' +  @CMGID + RIGHT(CONVERT(NVARCHAR(4),YEAR(@ExportDateTo)),2)            
            
  CREATE TABLE dbo.#LatestExtraction            
  (            
    MaxExtractDate DATETIME              
  )            
            
  SELECT @sSQL =            
  'INSERT INTO dbo.#LatestExtraction(MaxExtractDate) ' + CHAR(13) +            
  'SELECT ISNULL(MAX(A.ExtractDate), ''1900-01-01 '') ' + CHAR(13) +            
  'FROM ' +@ExtractDataTable + ' A  INNER JOIN (SELECT A.RPOSCode ' + CHAR(13) +            
  '                                             FROM ReportingPositions A INNER JOIN (SELECT RPOSCode ' + CHAR(13) +            
  '                                                                                   FROM ReportingPositions ' + CHAR(13) +            
  '                                                                                   WHERE IsSperI = 1) B ' + CHAR(13) +            
  '                       ON A.RPOSCodeReplacement = B.RPOSCode) B ' + CHAR(13) +            
  '       ON A.RPOSCode = B.RPOSCode  ' + CHAR(13) +                    
  '     INNER JOIN Companies C ' + CHAR(13) +            
  '       ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +            
  'WHERE C.CMGID = ''' + @CMGID + ''' ' + CHAR(13) +             
  '  AND A.InvoiceDate BETWEEN ''' + CONVERT(NVARCHAR,@ExportDateFrom,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +            
  '  AND (C.IncludeInSperISTExtract = 1 OR ' + CHAR(13) +               '       C.IncludeInSperIGLExtract = 1) '            
            
  EXEC(@sSQL)            
            
  SELECT TOP 1 @MaxExtractDate = MaxExtractDate            
  FROM  dbo.#LatestExtraction            
              
  SELECT @SelectMain =             
 'SELECT YearPeriod, ' + CHAR(13) +            
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
 '  REPLACE(CONVERT(NVARCHAR,LocalCurrencyAmount),N''.'',N'','') AS LocalCurrencyAmount, ' + CHAR(13) +            
 '  TransactionCurrency, ' + CHAR(13) +            
 '  TransactionCurrencyAmount, ' + CHAR(13) +            
    '--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" ' + CHAR(13) +            
    '/* ' + CHAR(13) +            
 '  QuantityPC, ' + CHAR(13) +             
 '  QuantityAltUnit, ' + CHAR(13) +            
 '  QuantityLoose, ' + CHAR(13) +            
 '  QuantityUnit ' + CHAR(13) +             
    '*/ ' + CHAR(13) +            
 '  REPLACE(CONVERT(NVARCHAR,QuantityPC),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +             
 '  REPLACE(CONVERT(NVARCHAR,QuantityAltUnit),N''.'',N'','') AS QuantityAltUnit, ' + CHAR(13) +            
 '       CASE WHEN QuantityLoose = 0 THEN '''' ' + CHAR(13) +            
 '       ELSE REPLACE(CONVERT(NVARCHAR,QuantityLoose),N''.'',N'','') ' + CHAR(13) +            
 '  END AS QuantityLoose, ' + CHAR(13) +            
 '  CASE WHEN QuantityLoose = 0 THEN '''' ' + CHAR(13) +            
 '       ELSE REPLACE(CONVERT(NVARCHAR,QuantityUnit),N''.'',N'','') ' + CHAR(13) +            
 '  END AS QuantityUnit ' + CHAR(13) +             
    '--FSL 20111205 END ' + CHAR(13) +            
/* GLOSS PERFORMANCE TESTING            
    ' ,'''','''','''','''','''','''','''',''''' + CHAR(13) +            
*/            
            
 'FROM ( ' + CHAR(13)            
            
    SELECT @Select1 =            
   'SELECT ''' + CONVERT(NVARCHAR(4), YEAR(@MaxExtractDate)) + ''' + N''.'' + ' + CHAR(13) +             
   ' ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), MONTH(@MaxExtractDate)),2) + ''' AS YearPeriod, ' + CHAR(13) +            
   ' N'''' AS CalendarDay, ' + CHAR(13) +            
   ' N'''' AS DataEntryYearPeriod, ' + CHAR(13) +            
   ' A.Version, ' + CHAR(13) +            
   ' A.ReportingUnit, ' + CHAR(13) +            
   ' A.UpperHierarchy, ' + CHAR(13) +            
   ' A.PartnerReportingUnit, ' + CHAR(13) +            
   ' A.PartnerUpperHierarchy, ' + CHAR(13) +            
   ' N'''' AS Shares, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017. Change RPOSCode logic */         
   --Original ' A.RPOSCode, ' + CHAR(13) +         
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else A.RPOSCode end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */         
   ' N'''' AS MovementType, ' + CHAR(13) +            
   ' A.MaterialLocal, ' + CHAR(13) +            
   ' A.MaterialGlobal, ' + CHAR(13) +            
   ' A.IntlArticleGPH, ' + CHAR(13) +            
   ' N'''' AS [Function], ' + CHAR(13) +            
   ' A.CountryOfDestination, ' + CHAR(13) +            
   ' A.CustomerLocal, ' + CHAR(13) +            
   ' N'''' AS AuditID, ' + CHAR(13) +            
   ' A.LocalCurrency, ' + CHAR(13) +            
   ' SUM(CONVERT(NUMERIC(27,2),A.LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +            
   ' N'''' AS TransactionCurrency, ' + CHAR(13) +            
   ' N'''' AS TransactionCurrencyAmount, ' + CHAR(13) +            
   ' --REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,2),A.QuantityPC))),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +            
            ' ' + CHAR(13) +            
            '--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" ' + CHAR(13) +            
            '/* ' + CHAR(13) +            
   ' REPLACE(CONVERT(NVARCHAR,SUM(A.QuantityPC)),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +            
   ' dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +            
   ' CASE WHEN SUM(A.QuantityLoose) = 0 THEN '''' ' + CHAR(13) +            
   '   ELSE REPLACE(CONVERT(NVARCHAR,SUM(A.QuantityLoose)),N''.'',N'','') ' + CHAR(13) +            
   ' END AS QuantityLoose, ' + CHAR(13) +            
            '*/ ' + CHAR(13) +            
   ' SUM(CONVERT(NUMERIC(27,6),A.QuantityPC)) AS QuantityPC, ' + CHAR(13) +            
   /** 03052016 WSEE Replace this to new with case when           
   ' SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) AS QuantityAltUnit, ' + CHAR(13) +            
    **/          
    /** 03052016  WSEE  Begin  Add 5811220000 filter **/   
    ' CASE WHEN  A.RPOSCode != ''5811220000'' THEN SUM(dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit)) ELSE 0 END  AS QuantityAltUnit,  ' + CHAR(13) +     
    /** WSEE  End  03052016 **/    
         
      
   ' SUM(A.QuantityLoose) AS QuantityLoose, ' + CHAR(13) +            
            '--FSL 20111205 END ' + CHAR(13) +            
            ' ' + CHAR(13) +            
   ' CASE WHEN SUM(A.QuantityLoose) = 0 THEN '''' ' + CHAR(13) +            
   '   ELSE A.QuantityUnit ' + CHAR(13) +            
   ' END AS QuantityUnit ' + CHAR(13)            
            
    SELECT @From1 =             
   'FROM ' + @ExtractDataTable + ' A  INNER JOIN (SELECT A.RPOSCode, A.IsDataFromStatistics ' + CHAR(13) +            
            '                                             FROM ReportingPositions A INNER JOIN (SELECT RPOSCode ' + CHAR(13) +            
            '                                                                                   FROM ReportingPositions ' + CHAR(13) +            
            '                                                                                   WHERE IsSperI = 1) B ' + CHAR(13) +            
            '                                                    ON A.RPOSCodeReplacement = B.RPOSCode) B ' + CHAR(13) +            
   ' ON A.RPOSCode = B.RPOSCode ' + CHAR(13) +            
   'INNER JOIN Companies C ' + CHAR(13) +            
   ' ON A.CompanyCode = C.CompanyCode ' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */
   'INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +
   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +
   'LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +
   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +
   'LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +
   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */
   'WHERE C.CMGID = ''' + @CMGID + ''' ' + CHAR(13) +            
   ' AND A.InvoiceDate BETWEEN ''' + CONVERT(NVARCHAR,@ExportDateFrom,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +            
   ' AND ((C.IncludeInSperISTExtract = 1 AND ISNULL(B.IsDataFromStatistics,0) = 1) OR ' + CHAR(13) +            
   ' (C.IncludeInSperIGLExtract = 1 AND ISNULL(B.IsDataFromStatistics,0) = 0) ' + CHAR(13) + 
   ' ) ' + CHAR(13) +        
   
/**  2017-May-9  WSEE  COMMENT
   'GROUP BY A.YearPeriod, ' + CHAR(13) +  
   **/  
     /**  2017-May-9  WSEE   REPLACE TO THIS **/ 
   'GROUP BY' + CHAR(13) +    
      
   ' A.Version, ' + CHAR(13) +            
   ' A.ReportingUnit, ' + CHAR(13) +            
   ' A.UpperHierarchy, ' + CHAR(13) +            
   ' A.PartnerReportingUnit, ' + CHAR(13) +            
   ' A.PartnerUpperHierarchy, ' + CHAR(13) +           
   /* IFRS, Zuoyin Xu */   
   ' A.RPOSCode, ' + CHAR(13) +     
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else A.RPOSCode end, ' + CHAR(13) +        
   /* IFRS, Zuoyin Xu */        
   ' A.MaterialLocal, ' + CHAR(13) + 
   ' A.MaterialGlobal, ' + CHAR(13) +            
   ' A.IntlArticleGPH, ' + CHAR(13) +            
   ' A.CountryOfDestination, ' + CHAR(13) +            
   ' A.CustomerLocal, ' + CHAR(13) +            
   ' A.LocalCurrency, ' + CHAR(13) +            
   ' A.QuantityUnit ' + CHAR(13) +            
            '   --dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, A.RPOSCode, A.QuantityAltUnit) ' + CHAR(13)             
            
            
              
    SELECT @Select2 =            
   'select ' + CHAR(13) +             
   ' P.YearPeriod, ' + CHAR(13) +             
   ' N'''' AS CalendarDay, ' + CHAR(13) +             
   ' N'''' AS DataEntryYearPeriod, ' + CHAR(13) +             
   ' P.Version, ' + CHAR(13) +             
   ' P.ReportingUnit, ' + CHAR(13) +             
   ' P.UpperHierarchy, ' + CHAR(13) +             
   ' P.PartnerReportingUnit, ' + CHAR(13) +             
   ' P.PartnerUpperHierarchy, ' + CHAR(13) +             
   ' N'''' AS Shares, ' + CHAR(13) +             
   ' P.RPOSCode, ' + CHAR(13) +             
   ' N'''' AS MovementType, ' + CHAR(13) +             
   ' P.MaterialLocal, ' + CHAR(13) +             
   ' P.MaterialGlobal, ' + CHAR(13) +             
   ' P.IntlArticleGPH, ' + CHAR(13) +      
   ' N'''' AS [Function], ' + CHAR(13) +             
   ' P.CountryOfDestination, ' + CHAR(13) +             
   ' P.CustomerLocal, ' + CHAR(13) +             
   ' N'''' AS AuditID, ' + CHAR(13) +             
   ' P.LocalCurrency,   ' + CHAR(13) +             
   ' SUM(CONVERT(NUMERIC(27,2),LocalCurrencyAmount)) AS LocalCurrencyAmount, ' + CHAR(13) +             
   ' '''' AS TransactionCurrency, ' + CHAR(13) +             
   ' '''' AS TransactionCurrencyAmount, ' + CHAR(13) +             
            '--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" ' + CHAR(13) +                                             
            '/* ' + CHAR(13) +             
   ' REPLACE(CONVERT(NVARCHAR,SUM(CONVERT(NUMERIC(27,6),P.QuantityPC))),N''.'',N'','') AS QuantityPC, ' + CHAR(13) +             
   ' REPLACE(CONVERT(NVARCHAR,SUM(P.QuantityAltUnit)),N''.'',N'','') AS QuantityAltUnit, ' + CHAR(13) +             
   ' CASE WHEN SUM(P.QuantityLoose) = 0 THEN '''' ' + CHAR(13) +             
   '   ELSE REPLACE(CONVERT(NVARCHAR,SUM(P.QuantityLoose)),N''.'',N'','') ' + CHAR(13) +             
   ' END AS QuantityLoose, ' + CHAR(13) +             
   ' CASE WHEN SUM(P.QuantityLoose) = 0 THEN '''' ' + CHAR(13) +             
   ' ELSE P.QuantityUnit ' + CHAR(13) +             
   ' END AS QuantityUnit ' + CHAR(13) +             
            '*/ ' + CHAR(13) +             
   ' SUM(CONVERT(NUMERIC(27,6),P.QuantityPC)) AS QuantityPC, ' + CHAR(13) +             
   ' SUM(P.QuantityAltUnit) AS QuantityAltUnit, ' + CHAR(13) +             
   ' SUM(P.QuantityLoose) AS QuantityLoose, ' + CHAR(13) +             
   ' P.QuantityUnit AS QuantityUnit ' + CHAR(13) +             
            '--FSL 20111205  END ' + CHAR(13)             
            
    SELECT @From2 =            
   'FROM  ( SELECT ''' + CONVERT(NVARCHAR(4), YEAR(@MaxExtractDate)) + ''' + N''.'' + ' + CHAR(13) +             
   '  ''' + RIGHT(N'00' + CONVERT(NVARCHAR(2), MONTH(@MaxExtractDate)),2) + ''' AS YearPeriod, ' + CHAR(13) +             
   '  A.Version, ' + CHAR(13) +            
   '  A.ReportingUnit, ' + CHAR(13) +             
   '  A.UpperHierarchy, ' + CHAR(13) +            
   '  A.PartnerReportingUnit, ' + CHAR(13) +             
   '  A.PartnerUpperHierarchy, ' + CHAR(13) +             
   /* IFRS, Zuoyin Xu 01-June-2017. Change RPOSCode logic */         
   --original '  B.RPOSCodeReplacement AS RPOSCode, ' + CHAR(13) +           
   ' Case when A.InvoiceDate >= convert(datetime, convert(varchar(10), E.DataValue,120)) then ISNULL(F.[DataValue], ''3011110000'') ' + CHAR(13) +
   '	  else B.RPOSCodeReplacement end AS RPOSCode, ' + CHAR(13) +   
   /* IFRS, Zuoyin Xu 01-June-2017 */              
   '  A.MaterialLocal, ' + CHAR(13) +             
   '  A.MaterialGlobal, ' + CHAR(13) +             
   '  A.IntlArticleGPH, ' + CHAR(13) +             
   '  A.CountryOfDestination, ' + CHAR(13) +             
   '  A.CustomerLocal, ' + CHAR(13) +             
   '  A.LocalCurrency, ' + CHAR(13) +             
   '  LocalCurrencyAmount, ' + CHAR(13) +        
   /** 03052016 WSEE add'5811240000' to the case when   
   '  CASE WHEN A.RPOSCode IN (''5811100000'', ''5811210000'',''5811240000'') ' + CHAR(13) +  **/   
   /** 14072016  WSEE  remove '5811240000' from the case when **/      
   '  CASE WHEN A.RPOSCode IN (''5811100000'', ''5811210000'') ' + CHAR(13) +              
   '   THEN QuantityPC ' + CHAR(13) +             
   '   ELSE 0 ' + CHAR(13) +             
   '  END QuantityPC, ' + CHAR(13) +             
   /** 03052016  WSEE Replace this with Case When           
'dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit)'  +CHAR(13)+          
**/          
   /** 03052016 WSEE Begin        
   '    CASE WHEN  A.RPOSCode != ''5811220000'' THEN dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) ELSE 0 END AS QuantityAltUnit, ' + CHAR(13) +            
  WSEE End   03052016 **/       
  /** 14072016 WSEE Begin **/       
   '    CASE WHEN  A.RPOSCode not in(''5811220000'', ''5811240000'') THEN dbo.GS_DB_FUN_CheckNeedAltQtyUnit(A.CompanyCode, A.UpperHierarchy, B.RPOSCodeReplacement, A.QuantityAltUnit) ELSE 0 END AS QuantityAltUnit, ' + CHAR(13) +            
 /** WSEE End   14072016 **/        
    
   '  QuantityLoose, ' + CHAR(13) +             
            '--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" ' + CHAR(13) +                                             
            '--                                      QuantityUnit ' + CHAR(13) +             
            ' ' + CHAR(13) +             
   '     CASE WHEN QuantityLoose = 0 THEN '''' ' + CHAR(13) +             
            '             ELSE QuantityUnit ' + CHAR(13) +             
            '        END QuantityUnit ' + CHAR(13) +             
            '--FSL 20111205 END ' + CHAR(13) +             
   ' FROM ' +@ExtractDataTable + ' A  INNER JOIN (SELECT RPOSCode, RPOSCodeReplacement ' + CHAR(13) +            
            '                                                FROM ReportingPositions ' + CHAR(13) +            
            '                                                WHERE RPOSCodeReplacement = ''3011110000'' ' + CHAR(13) +            
            '                                                  AND IsSperI = 1) B ' + CHAR(13) +            
   '  ON A.RPOSCode = B.RPOSCode ' + CHAR(13) +                      
   ' INNER JOIN Companies C ' + CHAR(13) +            
   '  ON A.CompanyCode = C.CompanyCode ' + CHAR(13) + 
   /* IFRS, Zuoyin Xu 01-June-2017 */
   ' INNER JOIN ScalaHU_1025..SC019100 D' + CHAR(13) +
   '	ON A.MaterialLocal = D.SC01001' + CHAR(13) +
   ' LEFT OUTER JOIN SelectionCriteria E --valid date' + CHAR(13) +
   '	ON A.CompanyCode = E.CompanyCode and E.[Type] = ''IFRS15''' + CHAR(13) +
   ' LEFT OUTER JOIN SelectionCriteria F --RPOSCode' + CHAR(13) +
   '	ON A.CompanyCode = F.CompanyCode and ''IFRS15-'' + D.SC01160 = F.[Type]' + CHAR(13) +
   /* IFRS, Zuoyin Xu 01-June-2017 */              
   ' WHERE C.CMGID = ''' + @CMGID + ''' ' + CHAR(13) +             
   '  AND A.InvoiceDate BETWEEN ''' + CONVERT(NVARCHAR,@ExportDateFrom,111) + ''' AND ''' + CONVERT(NVARCHAR,@ExportDateTo,111) + ''' ' + CHAR(13) +            
   '  AND C.IncludeInSperISTExtract = 1 ' + CHAR(13) +            
   ' ) P ' + CHAR(13) +             
   'GROUP BY P.YearPeriod, ' + CHAR(13) +            
   ' P.Version, ' + CHAR(13) +            
   ' P.ReportingUnit, ' + CHAR(13) +            
   ' P.UpperHierarchy, ' + CHAR(13) +            
   ' P.PartnerReportingUnit, ' + CHAR(13) +            
   ' P.PartnerUpperHierarchy, ' + CHAR(13) +            
   ' P.RPOSCode, ' + CHAR(13) +            
   ' P.MaterialLocal, ' + CHAR(13) +            
   ' P.MaterialGlobal, ' + CHAR(13) +            
   ' P.IntlArticleGPH, ' + CHAR(13) +            
   ' P.CountryOfDestination, ' + CHAR(13) +            
   ' P.CustomerLocal, ' + CHAR(13) +            
   ' P.LocalCurrency, ' + CHAR(13) +            
            '   P.QuantityUnit  ' + CHAR(13) +                           
  ')U ' + CHAR(13) +            
        '--FSL 20111205 BEGIN: Correction on error "Error converting data type nvarchar to numeric" ' + CHAR(13) +                                            
        '/* ' + CHAR(13) +         
  'WHERE CAST(REPLACE(U.LocalCurrencyAmount, '','', ''.'') AS NUMERIC) <> 0 OR  ' + CHAR(13) +            
  '  CAST(REPLACE(U.QuantityPC, '','', ''.'') AS NUMERIC) <> 0 ' + CHAR(13) +            
        '*/ ' + CHAR(13) +            
  'WHERE ISNULL(U.LocalCurrencyAmount,0) <> 0 OR  ' + CHAR(13) +            
  '  ISNULL(U.QuantityPC,0) <> 0 ' + CHAR(13) +            
  'ORDER BY U.RPOSCode ' + CHAR(13) +            
        '--FSL 20111205 END '            
            
/* GLOSS PERFORMANCE TESTING            
  EXEC('TRUNCATE TABLE GAUSS_OUTPUT ' +            
       'INSERT INTO GAUSS_OUTPUT ' +            
       @SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2)             
*/            
            
  --Print ( @SelectMain + @Select1)        
  --Print( + @From1 + ' UNION ALL ' )        
  --Print( + @Select2 + @From2 )          
  /** 2017-May-9 WSEE  Comment this
  EXEC( @SelectMain + @Select1 + @From1 + ' UNION ALL ' + @Select2 + @From2 ) 
  **/
  
/** 2017-May-9 WSEE Replace to this  BEGIN **/            
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
 /** 2017-May-9 WSEE END **/        
        
      

drop table dbo.#LatestExtraction            
END 
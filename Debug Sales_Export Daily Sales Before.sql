--exec Sales_Export '1025','1 Jan 2016', '31 Jan 2016',1  
SELECT YearPeriod, 
 UNION ALL 
SELECT '2016' + N'.' +  
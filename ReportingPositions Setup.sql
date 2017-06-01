--select * from ReportingPositions where RPOSCode = '3011110000'
--select * from ReportingPositions where RPOSCode = '3011130000'
--select * from ReportingPositions where RPOSCode like '30111%'

--update ReportingPositions set RPOSDesc = 'Net sales from sale of goods' where RPOSCode = '3011130000'
--update ReportingPositions set RPOSDesc = 'Net sales from sale of hardware/devices/instruments' where RPOSCode = '3011140000'
--update ReportingPositions set RPOSDesc = 'Net sales from services' where RPOSCode = '3011150000'
--update ReportingPositions set RPOSDesc = 'Net sales from shipping and handling' where RPOSCode = '3011160000'
--update ReportingPositions set RPOSDesc = 'Net sales from finance leasing contracts' where RPOSCode = '3011170000'

--G		Goods
--H		Hardware
--S		Service
--SH	Shipping & Handling
--SL	Service Level Agreement

insert ReportingPositions
select '3011130000', 'Net sales from sale of goods', SequenceNo, ColumnIndex, 
GroupCode, IsDaily, IsMonthly, IsSperI, IsSperIa, IsSperII, IsBS, IsNOA, IsARAP, GroupHeader,
'3011130000', '3011130000',
IsPositive, IsNeedCountryDestination, IsNeedShares, IsNeedFlow, IsNeedPartnerReportingUnit, IsNeedTransactionCurrency,
IsProduct, IsQuantity, IsPartnerBusinessField, BusinessDimension, IsCustomerKeyAccount, IsDataFromStatistics,
GlobalFunction, IsNeed3PInfo, DateEntered, IsActive, DefaultUpperHierarchy, DefaultPartnerReportingUnit,
DefaultMovementType, IsDivisionLevelOnly, IsRDCPRJ, IsRDCFCT, IsRDCITA, IsCPXENG, IsCPXIT, IsCPXRDO,
IsNeedCostType, DefaultCostType, DefaultCostCenter, IsNeedAltQty
from ReportingPositions where RPOSCode = '3011110000';

insert ReportingPositions
select '3011140000', 'Net sales from sale of hardware/devices/instruments', SequenceNo, ColumnIndex, 
GroupCode, IsDaily, IsMonthly, IsSperI, IsSperIa, IsSperII, IsBS, IsNOA, IsARAP, GroupHeader,
'3011140000', '3011140000',
IsPositive, IsNeedCountryDestination, IsNeedShares, IsNeedFlow, IsNeedPartnerReportingUnit, IsNeedTransactionCurrency,
IsProduct, IsQuantity, IsPartnerBusinessField, BusinessDimension, IsCustomerKeyAccount, IsDataFromStatistics,
GlobalFunction, IsNeed3PInfo, DateEntered, IsActive, DefaultUpperHierarchy, DefaultPartnerReportingUnit,
DefaultMovementType, IsDivisionLevelOnly, IsRDCPRJ, IsRDCFCT, IsRDCITA, IsCPXENG, IsCPXIT, IsCPXRDO,
IsNeedCostType, DefaultCostType, DefaultCostCenter, IsNeedAltQty
from ReportingPositions where RPOSCode = '3011110000'

insert ReportingPositions
select '3011150000', 'Net sales from services', SequenceNo, 
ColumnIndex, GroupCode, IsDaily, IsMonthly, IsSperI, IsSperIa, IsSperII, IsBS, IsNOA, IsARAP, GroupHeader,
'3011150000', '3011150000',
IsPositive, IsNeedCountryDestination, IsNeedShares, IsNeedFlow, IsNeedPartnerReportingUnit, IsNeedTransactionCurrency,
IsProduct, IsQuantity, IsPartnerBusinessField, BusinessDimension, IsCustomerKeyAccount, IsDataFromStatistics,
GlobalFunction, IsNeed3PInfo, DateEntered, IsActive, DefaultUpperHierarchy, DefaultPartnerReportingUnit,
DefaultMovementType, IsDivisionLevelOnly, IsRDCPRJ, IsRDCFCT, IsRDCITA, IsCPXENG, IsCPXIT, IsCPXRDO,
IsNeedCostType, DefaultCostType, DefaultCostCenter, IsNeedAltQty
from ReportingPositions where RPOSCode = '3011110000'

insert ReportingPositions
select '3011160000', 'Net sales from shipping and handling', SequenceNo, ColumnIndex, 
GroupCode, IsDaily, IsMonthly, IsSperI, IsSperIa, IsSperII, IsBS, IsNOA, IsARAP, GroupHeader,
'3011160000', '3011160000',
IsPositive, IsNeedCountryDestination, IsNeedShares, IsNeedFlow, IsNeedPartnerReportingUnit, IsNeedTransactionCurrency,
IsProduct, IsQuantity, IsPartnerBusinessField, BusinessDimension, IsCustomerKeyAccount, IsDataFromStatistics,
GlobalFunction, IsNeed3PInfo, DateEntered, IsActive, DefaultUpperHierarchy, DefaultPartnerReportingUnit,
DefaultMovementType, IsDivisionLevelOnly, IsRDCPRJ, IsRDCFCT, IsRDCITA, IsCPXENG, IsCPXIT, IsCPXRDO,
IsNeedCostType, DefaultCostType, DefaultCostCenter, IsNeedAltQty
from ReportingPositions where RPOSCode = '3011110000'

insert ReportingPositions
select '3011170000', 'Net sales from finance leasing contracts', SequenceNo, ColumnIndex, 
GroupCode, IsDaily, IsMonthly, IsSperI, IsSperIa, IsSperII, IsBS, IsNOA, IsARAP, GroupHeader,
'3011170000', '3011170000',
IsPositive, IsNeedCountryDestination, IsNeedShares, IsNeedFlow, IsNeedPartnerReportingUnit, IsNeedTransactionCurrency,
IsProduct, IsQuantity, IsPartnerBusinessField, BusinessDimension, IsCustomerKeyAccount, IsDataFromStatistics,
GlobalFunction, IsNeed3PInfo, DateEntered, IsActive, DefaultUpperHierarchy, DefaultPartnerReportingUnit,
DefaultMovementType, IsDivisionLevelOnly, IsRDCPRJ, IsRDCFCT, IsRDCITA, IsCPXENG, IsCPXIT, IsCPXRDO,
IsNeedCostType, DefaultCostType, DefaultCostCenter, IsNeedAltQty
from ReportingPositions where RPOSCode = '3011110000'
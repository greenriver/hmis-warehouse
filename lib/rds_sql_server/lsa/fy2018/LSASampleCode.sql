/**********************************************************************
LSA Sample Code
Supplement to The Longitudinal System Analysis 2018 HMIS Programming Specifications Version 1.2

Will generate tables in the structure of LSA upload files:
	LSAReport
	LSAHousehold
	LSAPerson
	LSACalculated

Requires:
	Reference tables ref_Calendar and ref_Populations - create script LSAReferenceTables.sql
	Tables of HMIS data in the structure of HMIS CSV v6.12
		-hmis_Organization
		-hmis_Project
		-hmis_Funder
		-hmis_ProjectCoC
		-hmis_Inventory
		-hmis_Geography
		-hmis_Client
		-hmis_Enrollment
		-hmis_EnrollmentCoC
		-hmis_Services
		-hmis_HealthAndDV
		-hmis_Exit

10/11/2018 - uploaded to github v1.22
10/15/2018 - corrections and addition of some indexes 

4.1 Create Intermediate Tables 
**********************************************************************/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id ('active_Enrollment') is null 
begin
	CREATE TABLE dbo.active_Enrollment(
		EnrollmentID varchar(32) NOT NULL,
		PersonalID varchar(32) NOT NULL,
		HouseholdID varchar(32) NOT NULL,
		RelationshipToHoH int NULL,
		EntryDate date NULL,
		MoveInDate date NULL,
		ExitDate date NULL,
		AgeDate date NULL,
		AgeGroup int NULL,
		MostRecent int NULL,
		HHType int NULL,
		ProjectID varchar(32) NULL,
		ProjectType int NULL,
		TrackingMethod int NULL,
		PRIMARY KEY (EnrollmentID) 
	)
	;
end
else delete from active_Enrollment

if not exists (select * from sys.indexes where name = 'ix_active_Enrollment_PersonalID_HouseholdID')
begin
	create index ix_active_Enrollment_PersonalID_HouseholdID 
		on active_Enrollment (PersonalID, HouseholdID) include (AgeGroup)
end 

if object_id ('active_Household') is null
begin
CREATE TABLE dbo.active_Household(
	HouseholdID varchar(32) NOT NULL,
	HoHID varchar(32) NULL,
	HHType int NULL,
	ProjectID varchar(32) NULL,
	ProjectType int NULL,
	TrackingMethod int NULL,
	MoveInDate date NULL,
	HHChronic int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	HHAdult int NULL,
	HHChild int NULL,
	HHNoDOB int NULL,
	AC3Plus int NULL,
	PRIMARY KEY (HouseholdID) 
);
end
else delete from active_Household


if not exists (select * from sys.indexes where name = 'ix_active_Household_HoHID_HHType')
begin
	create index ix_active_Household_HoHID_HHType 
		on active_Household (HoHID, HHType) include (ProjectType)
end

if object_id ('ch_Enrollment') is null 
begin
CREATE TABLE dbo.ch_Enrollment(
	PersonalID varchar(32) NULL,
	EnrollmentID varchar(32) NOT NULL,
	ProjectType int NULL,
	TrackingMethod int NULL,
	StartDate date NULL,
	MoveInDate date NULL,
	StopDate date NULL
    PRIMARY KEY (EnrollmentID) 
)
;
end
else delete from ch_Enrollment

if not exists (select * from sys.indexes where name = 'ix_ch_Enrollment_PersonalID_ProjectType')
begin
create index ix_ch_Enrollment_PersonalID_ProjectType 
	on ch_Enrollment (PersonalID, ProjectType) include (StartDate, StopDate) 
end

if object_id ('ch_Episodes') is not null drop table ch_Episodes
CREATE TABLE dbo.ch_Episodes(
	PersonalID varchar(32) NULL,
	episodeStart date NULL,
	episodeEnd date NULL,
	episodeDays int NULL
)
;

if object_id ('ch_Exclude') is not null drop table ch_Exclude
CREATE TABLE dbo.ch_Exclude(
	PersonalID varchar(32) NOT NULL,
	excludeDate date NOT NULL,
	PRIMARY KEY (PersonalID, excludeDate) 
)
;

if object_id ('ch_Time') is not null drop table ch_Time
CREATE TABLE dbo.ch_Time(
	PersonalID varchar(32) NOT NULL,
	chDate date NOT NULL,
	PRIMARY KEY (PersonalID, chDate)
)
;

if object_id ('dq_Enrollment') is null 
begin
CREATE TABLE dbo.dq_Enrollment(
	EnrollmentID varchar(32) NOT NULL,
	PersonalID varchar(32) NULL,
	HouseholdID varchar(32) NULL,
	RelationshipToHoH int NULL,
	ProjectType int NULL,
	EntryDate date NULL,
	MoveInDate date NULL,
	ExitDate date NULL,
	Adult int NULL,
	SSNValid int NULL,
	PRIMARY KEY (EnrollmentID) 
)
;
end
else delete from dq_Enrollment

if not exists (select * from sys.indexes where name = 'ix_dq_Enrollment_PersonalID_HouseholdID')
begin
	create index ix_dq_Enrollment_PersonalID_HouseholdID
		on dq_Enrollment (PersonalID, HouseholdID) include (RelationshipToHoH, Adult)
end

if object_id ('ex_Enrollment') is null 
begin
CREATE TABLE dbo.ex_Enrollment(
	Cohort int NOT NULL,
	HoHID varchar(32) NOT NULL,
	HHType int NOT NULL,
	EnrollmentID varchar(32) NOT NULL,
	ProjectType int NULL,
	EntryDate date NULL,
	MoveInDate date NULL,
	ExitDate date NULL,
	ExitTo int NULL,
	Active bit NULL,
	PRIMARY KEY (EnrollmentID) 
)
;
end
else delete from ex_Enrollment

if not exists (select * from sys.indexes where name = 'ix_ex_Enrollment_Cohort_HoHID_HHType')
begin
	create index ix_ex_Enrollment_Cohort_HoHID_HHType 
		on ex_Enrollment (Cohort, HoHID, HHType) include (EntryDate, ExitDate, ExitTo)
end

if object_id ('lsa_Calculated') is not null drop table lsa_Calculated
CREATE TABLE dbo.lsa_Calculated(
	Value int NULL,
	Cohort int NULL,
	Universe int NULL,
	HHType int NULL,
	Population int NULL,
	SystemPath int NULL,
	ProjectID varchar(32) NULL,
	ReportRow int NULL,
	ReportID int NULL
)
;

if object_id ('lsa_Exit') is not null drop table lsa_Exit
CREATE TABLE dbo.lsa_Exit(
	RowTotal int NULL,
	Cohort int NULL,
	Stat int NULL,
	ExitFrom int NULL,
	ExitTo int NULL,
	ReturnTime int NULL,
	HHType int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HoHRace int NULL,
	HoHEthnicity int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	AC3Plus int NULL,
	SystemPath int NULL,
	ReportID int NULL
)
;

if object_id ('lsa_Inventory') is not null drop table lsa_Inventory
if object_id ('lsa_Geography') is not null drop table lsa_Geography
if object_id ('lsa_Funder') is not null drop table lsa_Funder
if object_id ('lsa_Project') is not null drop table lsa_Project
if object_id ('lsa_Organization') is not null drop table lsa_Organization
CREATE TABLE dbo.lsa_Organization(
	OrganizationID varchar(32) NOT NULL,
	OrganizationName varchar(50) NOT NULL,
	OrganizationCommonName varchar(50) NULL,
	DateCreated datetime NOT NULL,
	DateUpdated datetime NOT NULL,
	UserID varchar(32) NULL,
	DateDeleted datetime NULL,
	ExportID varchar(32) NOT NULL,
	PRIMARY KEY (OrganizationID) 
)
;
CREATE TABLE dbo.lsa_Project(
	ProjectID varchar(32) NOT NULL,
	OrganizationID varchar(32) NULL,
	ProjectName varchar(50) NOT NULL,
	ProjectCommonName varchar(50) NULL,
	OperatingStartDate date NULL,
	OperatingEndDate date NULL,
	ContinuumProject int NOT NULL,
	ProjectType int NOT NULL,
	ResidentialAffiliation int NULL,
	TrackingMethod int NULL,
	TargetPopulation int NULL,
	VictimServicesProvider int NOT NULL,
	HousingType int NOT NULL,
	PITCount int NULL,
	DateCreated datetime NOT NULL,
	DateUpdated datetime NOT NULL,
	UserID varchar(32) NULL,
	DateDeleted datetime NULL,
	ExportID varchar(32) NOT NULL,
	PRIMARY KEY (ProjectID) 
)
;
CREATE TABLE dbo.lsa_Inventory(
	InventoryID varchar(32) NOT NULL,
	ProjectID varchar(32) NOT NULL,
	CoCCode varchar(6) NOT NULL,
	InformationDate date NOT NULL,
	HouseholdType int NOT NULL,
	Availability int NULL,
	UnitInventory int NOT NULL,
	BedInventory int NOT NULL,
	CHBedInventory int NULL,
	VetBedInventory int NULL,
	YouthBedInventory int NULL,
	BedType int NULL,
	InventoryStartDate date NOT NULL,
	InventoryEndDate date NULL,
	HMISParticipatingBeds int NOT NULL,
	DateCreated datetime NOT NULL,
	DateUpdated datetime NOT NULL,
	UserID varchar(32) NULL,
	DateDeleted datetime NULL,
	ExportID varchar(32) NOT NULL,
	PRIMARY KEY (InventoryID),
	FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
)
;

CREATE TABLE dbo.lsa_Funder(
	FunderID varchar(32) NOT NULL,
	ProjectID varchar(32) NOT NULL,
	Funder int NOT NULL,
	GrantID varchar(32) NULL,
	StartDate date NOT NULL,
	EndDate date NULL,
	DateCreated datetime NOT NULL,
	DateUpdated datetime NOT NULL,
	UserID varchar(32) NULL,
	DateDeleted datetime NULL,
	ExportID varchar(32) NOT NULL,
	FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
)
;

CREATE TABLE dbo.lsa_Geography(
	GeographyID varchar(32) NOT NULL,
	ProjectID varchar(32) NOT NULL,
	CoCCode varchar(6) NOT NULL,
	InformationDate datetime NOT NULL,
	Geocode varchar(6) NOT NULL,
	GeographyType int NOT NULL,
	Address1 varchar(50) NULL,
	Address2 varchar(50) NULL,
	City varchar(50) NULL,
	State varchar(2) NULL,
	ZIP varchar(5) NULL,
	DateCreated datetime NOT NULL,
	DateUpdated datetime NOT NULL,
	UserID varchar(32) NULL,
	DateDeleted datetime NULL,
	ExportID varchar(32) NOT NULL,
	PRIMARY KEY (GeographyID),
	FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
)
;

if object_id ('lsa_Household') is not null drop table lsa_Household
CREATE TABLE dbo.lsa_Household(
	RowTotal int NULL,
	Stat int NULL,
	ReturnTime int NULL,
	HHType int NULL,
	HHChronic int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HoHRace int NULL,
	HoHEthnicity int NULL,
	HHAdult int NULL,
	HHChild int NULL,
	HHNoDOB int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	ESTStatus int NULL,
	RRHStatus int NULL,
	RRHMoveIn int NULL,
	PSHStatus int NULL,
	PSHMoveIn int NULL,
	ESDays int NULL,
	THDays int NULL,
	ESTDays int NULL,
	ESTGeography int NULL,
	ESTLivingSit int NULL,
	ESTDestination int NULL,
	RRHPreMoveInDays int NULL,
	RRHPSHPreMoveInDays int NULL,
	RRHHousedDays int NULL,
	SystemDaysNotPSHHoused int NULL,
	RRHGeography int NULL,
	RRHLivingSit int NULL,
	RRHDestination int NULL,
	SystemHomelessDays int NULL,
	Other3917Days int NULL,
	TotalHomelessDays int NULL,
	PSHGeography int NULL,
	PSHLivingSit int NULL,
	PSHDestination int NULL,
	PSHHousedDays int NULL,
	SystemPath int NULL,
	ReportID int NULL
)
;

if object_id ('lsa_Person') is not null drop table lsa_Person
CREATE TABLE dbo.lsa_Person(
	RowTotal int NULL,
	Age int NULL,
	Gender int NULL,
	Race int NULL,
	Ethnicity int NULL,
	VetStatus int NULL,
	DisabilityStatus int NULL,
	CHTime int NULL,
	CHTimeStatus int NULL,
	DVStatus int NULL,
	HHTypeEST int NULL,
	HoHEST int NULL,
	HHTypeRRH int NULL,
	HoHRRH int NULL,
	HHTypePSH int NULL,
	HoHPSH int NULL,
	HHChronic int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	AC3Plus int NULL,
	ReportID int NULL
)
;

if object_id ('lsa_Report') is not null drop table lsa_Report
CREATE TABLE dbo.lsa_Report(
	ReportID int NOT NULL,
	ReportDate datetime NOT NULL,
	ReportStart date NOT NULL,
	ReportEnd date NOT NULL,
	ReportCoC varchar(6) NOT NULL,
	SoftwareVendor varchar(50) NOT NULL,
	SoftwareName varchar(50) NOT NULL,
	VendorContact varchar(50) NOT NULL,
	VendorEmail varchar(50) NOT NULL,
	LSAScope int NOT NULL,
	UnduplicatedClient1 int NULL,
	UnduplicatedClient3 int NULL,
	UnduplicatedAdult1 int NULL,
	UnduplicatedAdult3 int NULL,
	AdultHoHEntry1 int NULL,
	AdultHoHEntry3 int NULL,
	ClientEntry1 int NULL,
	ClientEntry3 int NULL,
	ClientExit1 int NULL,
	ClientExit3 int NULL,
	Household1 int NULL,
	Household3 int NULL,
	HoHPermToPH1 int NULL,
	HoHPermToPH3 int NULL,
	NoCoC int NULL,
	SSNNotProvided int NULL,
	SSNMissingOrInvalid int NULL,
	ClientSSNNotUnique int NULL,
	DistinctSSNValueNotUnique int NULL,
	DOB1 int NULL,
	DOB3 int NULL,
	Gender1 int NULL,
	Gender3 int NULL,
	Race1 int NULL,
	Race3 int NULL,
	Ethnicity1 int NULL,
	Ethnicity3 int NULL,
	VetStatus1 int NULL,
	VetStatus3 int NULL,
	RelationshipToHoH1 int NULL,
	RelationshipToHoH3 int NULL,
	DisablingCond1 int NULL,
	DisablingCond3 int NULL,
	LivingSituation1 int NULL,
	LivingSituation3 int NULL,
	LengthOfStay1 int NULL,
	LengthOfStay3 int NULL,
	HomelessDate1 int NULL,
	HomelessDate3 int NULL,
	TimesHomeless1 int NULL,
	TimesHomeless3 int NULL,
	MonthsHomeless1 int NULL,
	MonthsHomeless3 int NULL,
	DV1 int NULL,
	DV3 int NULL,
	Destination1 int NULL,
	Destination3 int NULL,
	NotOneHoH1 int NULL,
	NotOneHoH3 int NULL,
	MoveInDate1 int NULL,
	MoveInDate3 int NULL
)
;

--NOTE: set production values based on system / user parameters
INSERT [dbo].[lsa_Report] ([ReportID]
	, [ReportDate], [ReportStart], [ReportEnd], [ReportCoC]
	, [SoftwareVendor], [SoftwareName], [VendorContact], [VendorEmail]
	, [LSAScope]) 
VALUES (1009
	, CAST(N'2018-05-07T17:47:35.977' AS DateTime), CAST(N'2016-10-01' AS Date)
		, CAST(N'2017-09-30' AS Date), N'XX-500'
	, N'Tamale Inc.', N'Tamale Online', N'Molly', N'molly@squarepegdata.com'
	, 1)

if object_id ('sys_Enrollment') is null 
begin
CREATE TABLE dbo.sys_Enrollment(
	HoHID varchar(32) not null,
	HHType int not null,
	EnrollmentID varchar(32) not null,
	ProjectType int NULL,
	EntryDate date NULL,
	MoveInDate date NULL,
	ExitDate date NULL,
	Active bit NULL,
    PRIMARY KEY (EnrollmentID) 
)
;
end
else delete from sys_Enrollment

if not exists (select * from sys.indexes where name = 'ix_sys_Enrollment_HoHID_HHType')
begin
	create index ix_sys_Enrollment_HoHID_HHType 
		on sys_Enrollment (HoHID, HHType) include (ProjectType, EntryDate, ExitDate)
end

if object_id ('sys_Time') is not null drop table sys_Time
CREATE TABLE dbo.sys_Time(
	HoHID varchar(32) NOT NULL,
	HHType int NOT NULL,
	sysDate date NOT NULL,
	sysStatus varchar(8) NULL,
	PRIMARY KEY (HoHID,HHType,sysDate) 
)
;

if object_id ('tmp_CohortDates') is not null drop table tmp_CohortDates
CREATE TABLE dbo.tmp_CohortDates(
	Cohort int NOT NULL,
	CohortStart date NULL,
	CohortEnd date NULL,
	PRIMARY KEY (Cohort)
)
;

if object_id ('tmp_Exit') is null 
begin
CREATE TABLE dbo.tmp_Exit(
	HoHID varchar(32) NOT NULL,
	EnrollmentID varchar(32) NULL,
	EntryDate date NULL,
	ExitDate date NULL,
	ReturnDate date NULL,
	StatEnrollmentID varchar(32) NULL,
	LastInactive date NULL,
	Cohort int NOT NULL,
	Stat int NULL,
	ExitFrom int NOT NULL,
	ExitTo int NOT NULL,
	ReturnTime int NULL,
	HHType int NOT NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HoHRace int NULL,
	HoHEthnicity int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	AC3Plus int NULL,
	SystemPath int NULL,
	ReportID int NULL,
	PRIMARY KEY (Cohort, HoHID, HHType) 
)
;
end 
else delete from tmp_Exit

if not exists (select * from sys.indexes where name = 'ix_tmp_Exit_EntryDate_ExitDate_Stat')
begin
	create index ix_tmp_Exit_EntryDate_ExitDate_Stat 
		on tmp_Exit (EntryDate, ExitDate, Stat) include (ExitFrom)
end



if object_id ('tmp_Household') is null 
begin
CREATE TABLE dbo.tmp_Household(
	HoHID varchar(32) NOT NULL,
	LastInactive date NULL,
	Stat int NULL,
	StatEnrollmentID varchar(32) NULL,
	ReturnTime int NULL,
	HHType int NOT NULL,
	HHChronic int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HoHRace int NULL,
	HoHEthnicity int NULL,
	HHAdult int NULL,
	HHChild int NULL,
	HHNoDOB int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	ESTStatus int NULL,
	RRHStatus int NULL,
	RRHMoveIn int NULL,
	PSHStatus int NULL,
	PSHMoveIn int NULL,
	ESDays int NULL,
	THDays int NULL,
	ESTDays int NULL,
	ESTGeography int NULL,
	ESTLivingSit int NULL,
	ESTDestination int NULL,
	RRHPreMoveInDays int NULL,
	RRHPSHPreMoveInDays int NULL,
	RRHHousedDays int NULL,
	SystemDaysnotPSHHoused int NULL,
	RRHGeography int NULL,
	RRHLivingSit int NULL,
	RRHDestination int NULL,
	SystemHomelessDays int NULL,
	Other3917Days int NULL,
	TotalHomelessDays int NULL,
	PSHGeography int NULL,
	PSHLivingSit int NULL,
	PSHDestination int NULL,
	PSHHousedDays int NULL,
	SystemPath int NULL,
	ReportID int NULL,
	FirstEntry date NULL,
	LastActive date NULL,
	PRIMARY KEY (HoHID, HHType) 
)
;
end
else delete from tmp_Household

if object_id ('tmp_Person') is null 
begin
CREATE TABLE dbo.tmp_Person(
	PersonalID varchar(32) NOT NULL,
	HoHAdult int NULL,
	LastActive date NULL,
	CHStart date NULL,
	Age int NULL,
	Gender int NULL,
	Race int NULL,
	Ethnicity int NULL,
	VetStatus int NULL,
	DisabilityStatus int NULL,
	CHTime int NULL,
	CHTimeStatus int NULL,
	DVStatus int NULL,
	HHTypeEST int NULL,
	HoHEST int NULL,
	HHTypeRRH int NULL,
	HoHRRH int NULL,
	HHTypePSH int NULL,
	HoHPSH int NULL,
	HHChronic int NULL,
	HHVet int NULL,
	HHDisability int NULL,
	HHFleeingDV int NULL,
	HHAdultAge int NULL,
	HHParent int NULL,
	AC3Plus int NULL,
	ReportID int NULL,
	PRIMARY KEY (PersonalID) 
)
; 
end
else delete from tmp_Person

/**********************************************************************
4.2 Get Project Records / lsa_Project
**********************************************************************/
delete from lsa_Inventory
delete from lsa_Geography
delete from lsa_Funder
delete from lsa_Project
delete from lsa_Organization

insert into lsa_Project
	(ProjectID, OrganizationID, ProjectName
	 , OperatingStartDate, OperatingEndDate
	 , ContinuumProject, ProjectType, TrackingMethod
	 , TargetPopulation, VictimServicesProvider, HousingType
	 , DateCreated, DateUpdated, ExportID)
select distinct 
	hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 50)
	, hp.OperatingStartDate, hp.OperatingEndDate
	, hp.ContinuumProject, hp.ProjectType, hp.TrackingMethod
	, hp.TargetPopulation, hp.VictimServicesProvider, hp.HousingType
	, hp.DateCreated, hp.DateUpdated, convert(varchar,rpt.ReportID)
from hmis_Project hp
inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
where hp.ContinuumProject = 1 
	--include only projects that were operating during the report period
	and (hp.OperatingEndDate is null or hp.OperatingEndDate >= rpt.ReportStart)  
	and hp.ProjectType in (1,2,3,8,9,10,13)
/**********************************************************************
4.3 Get Organization Records / lsa_Organization
**********************************************************************/
insert into lsa_Organization
	(OrganizationID, OrganizationName, DateCreated, DateUpdated, ExportID)
select distinct ho.OrganizationID
      ,left(ho.OrganizationName, 50)
      ,ho.DateCreated, ho.DateUpdated, convert(varchar,rpt.ReportID)
from hmis_Organization ho
inner join lsa_Report rpt on rpt.ReportDate >= ho.DateUpdated
--include only organizations associated with active projects
inner join lsa_Project lp on lp.OrganizationID = ho.OrganizationID
where ho.DateDeleted is null 

/**********************************************************************
4.4 Get Funder Records / lsa_Funder
**********************************************************************/
insert into lsa_Funder	
	(FunderID, ProjectID, Funder, StartDate, EndDate, DateCreated, DateUpdated, ExportID)
select distinct hf.FunderID, hf.ProjectID, hf.Funder, hf.StartDate, hf.EndDate
	, hf.DateCreated, hf.DateUpdated, convert(varchar, rpt.ReportID)
from hmis_Funder hf
inner join lsa_Report rpt on hf.StartDate <= rpt.ReportEnd
inner join lsa_Project lp on lp.ProjectID = hf.ProjectID
where hf.DateDeleted is null 
	--get only funding sources active in the report period
	and (hf.EndDate is null or hf.EndDate >= rpt.ReportStart) 

/**********************************************************************
4.5 Get Inventory Records / lsa_Inventory
**********************************************************************/
insert into lsa_Inventory 
	(InventoryID, ProjectID, CoCCode, InformationDate, HouseholdType
	 , Availability, UnitInventory, BedInventory
	 , CHBedInventory, VetBedInventory, YouthBedInventory, BedType
	 , InventoryStartDate, InventoryEndDate, HMISParticipatingBeds
	 , DateCreated, DateUpdated, ExportID)
select distinct hi.InventoryID, hi.ProjectID, hi.CoCCode
	, hi.InformationDate, hi.HouseholdType
	, case when lp.ProjectType = 1 then hi.Availability else null end 
	, hi.UnitInventory, hi.BedInventory
	, case when lp.ProjectType = 3 then hi.CHBedInventory else null end 
	, hi.VetBedInventory, hi.YouthBedInventory
	, case when lp.ProjectType = 1 then hi.BedType else null end
	, hi.InventoryStartDate, hi.InventoryEndDate, hi.HMISParticipatingBeds
	, hi.DateCreated, hi.DateUpdated, convert(varchar, rpt.ReportID)
from hmis_Inventory hi
inner join lsa_Report rpt on hi.InventoryStartDate <= rpt.ReportEnd
	--get only inventory associated with the report CoC...
	and hi.CoCCode = rpt.ReportCoC
inner join lsa_Project lp on lp.ProjectID = hi.ProjectID
where hi.DateDeleted is null and
	--...and active during the report period
	(hi.InventoryEndDate is null or hi.InventoryEndDate >= rpt.ReportStart)

/**********************************************************************
4.6 Get Geography Records / lsa_Geography
**********************************************************************/
insert into lsa_Geography
	(GeographyID, ProjectID, CoCCode, InformationDate
	, Geocode, GeographyType
	, Address1, Address2, City, State, ZIP
	, DateCreated, DateUpdated, ExportID)
select distinct hg.GeographyID, hg.ProjectID, hg.CoCCode, hg.InformationDate
	, hg.Geocode, hg.GeographyType
	, hg.Address1, hg.Address2, hg.City, hg.State, hg.ZIP
	, hg.DateCreated, hg.DateUpdated, convert(varchar, rpt.ReportID)
from hmis_Geography hg
--limit to records that are associated with the report CoC...
inner join lsa_Report rpt on hg.InformationDate <= rpt.ReportEnd and hg.CoCCode = rpt.ReportCoC
inner join lsa_Project lp on lp.ProjectID = hg.ProjectID
left outer join hmis_Geography later on later.ProjectID = hg.ProjectID
	and later.DateDeleted is null 
	and (later.InformationDate > hg.InformationDate 
		or (later.InformationDate = hg.InformationDate 
			and later.DateUpdated > hg.DateUpdated))
where hg.DateDeleted is null and
	--and only the most recent record for each project dated before ReportEnd
	later.GeographyID is null

/*************************************************************************
4.7 Get Active Household IDs
**********************************************************************/
delete from active_Household

insert into active_Household (HouseholdID, HoHID, MoveInDate
	, ProjectID, ProjectType, TrackingMethod)
select distinct hn.HouseholdID
	, coalesce ((select min(PersonalID) 
			from hmis_Enrollment 
			where HouseholdID = hn.HouseholdID and RelationshipToHoH = 1)  
		, (select min(PersonalID) 
			from hmis_Enrollment 
			where HouseholdID = hn.HouseholdID))
	, case when p.ProjectType in (3,13) then 
			(select min(MoveInDate) 
			from hmis_Enrollment 
			where HouseholdID = hn.HouseholdID) else null end
	, p.ProjectID, p.ProjectType, p.TrackingMethod
from lsa_Report rpt
inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
inner join lsa_Project p on p.ProjectID = hn.ProjectID
left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID 
	and x.ExitDate <= rpt.ReportEnd
left outer join hmis_Services bn on bn.EnrollmentID = hn.EnrollmentID
	and bn.DateProvided between rpt.ReportStart and rpt.ReportEnd
	and bn.RecordType = 200 
where ((x.ExitDate >= rpt.ReportStart and x.ExitDate > hn.EntryDate)
		or x.ExitDate is null)
	and p.ProjectType in (1,2,3,8,13)
	and p.ContinuumProject = 1
	and ((p.TrackingMethod is null or p.TrackingMethod <> 3) or bn.DateProvided is not null)
	and (select top 1 coc.CoCCode
		from hmis_EnrollmentCoC coc
		where coc.EnrollmentID = hn.EnrollmentID
			and coc.InformationDate <= rpt.ReportEnd
		order by coc.InformationDate desc) = rpt.ReportCoC

/*************************************************************************
4.8 Get Active Enrollments and Associated AgeDates
**********************************************************************/
delete from active_Enrollment

insert into active_Enrollment 
	(EnrollmentID, PersonalID, HouseholdID
	, RelationshipToHoH, AgeDate
	, EntryDate, MoveInDate, ExitDate
	, ProjectID, ProjectType, TrackingMethod)
select distinct hn.EnrollmentID, hn.PersonalID, hn.HouseholdID
	, case when hn.PersonalID = hhid.HoHID then 1
		when hn.RelationshipToHoH = 1 and hn.PersonalID <> hhid.HoHID then 99
		when hn.RelationshipToHoH not in (1,2,3,4,5) then 99
		else hn.RelationshipToHoH end
	, case when hn.EntryDate >= rpt.ReportStart then hn.EntryDate
		else rpt.ReportStart end
	, hn.EntryDate
	, hhid.MoveInDate
	, x.ExitDate
	, hhid.ProjectID, hhid.ProjectType, hhid.TrackingMethod
from lsa_Report rpt
inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
inner join active_Household hhid on hhid.HouseholdID = hn.HouseholdID
left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID
	and x.ExitDate <= rpt.ReportEnd
--CHANGE 9/28/2018: where ExitDate >= ReportStart (was just >)
where ((x.ExitDate >= rpt.ReportStart and x.ExitDate > hn.EntryDate)
		or x.ExitDate is null)

/*************************************************************************
4.9 Set Age Group for Each Active Enrollment
**********************************************************************/
update n
set n.AgeGroup = case
	when c.DOBDataQuality in (8,9) then 98
	when c.DOB is null 
		--NOTE 9/4/2018 - if database default date value is not 1/1/1900, 
		--use database default
		or c.DOB = '1/1/1900'
		or c.DOB > n.EntryDate
		or (n.RelationshipToHoH = 1 and c.DOB = n.EntryDate)
		or DATEADD(yy, 105, c.DOB) <= n.AgeDate 
		or c.DOBDataQuality is null
		or c.DOBDataQuality not in (1,2) then 99
	when DATEADD(yy, 65, c.DOB) <= n.AgeDate then 65
	when DATEADD(yy, 55, c.DOB) <= n.AgeDate then 64
	when DATEADD(yy, 45, c.DOB) <= n.AgeDate then 54
	when DATEADD(yy, 35, c.DOB) <= n.AgeDate then 44
	when DATEADD(yy, 25, c.DOB) <= n.AgeDate then 34
	when DATEADD(yy, 22, c.DOB) <= n.AgeDate then 24
	when DATEADD(yy, 18, c.DOB) <= n.AgeDate then 21
	when DATEADD(yy, 6, c.DOB) <= n.AgeDate then 17
	when DATEADD(yy, 3, c.DOB) <= n.AgeDate then 5
	when DATEADD(yy, 1, c.DOB) <= n.AgeDate then 2
	else 0 end 	 
from active_Enrollment n
inner join hmis_Client c on c.PersonalID = n.PersonalID

/*************************************************************************
4.10 Set HHType for Active HouseholdIDs 
**********************************************************************/
update hhid
set hhid.HHAdult = (select count(distinct an.PersonalID)
		from active_Enrollment an
		where an.HouseholdID = hhid.HouseholdID 
			and an.AgeGroup between 18 and 65)
	, HHChild  = (select count(distinct an.PersonalID)
		from active_Enrollment an
		where an.HouseholdID = hhid.HouseholdID 
			and an.AgeGroup < 18) 
	, HHNoDOB  = (select count(distinct an.PersonalID)
		from active_Enrollment an
		where an.HouseholdID = hhid.HouseholdID 
			and an.AgeGroup in (98,99))
from active_Household hhid

update hhid
set hhid.HHType = case
	when HHAdult > 0 and HHChild > 0 then 2
	when HHNoDOB > 0 then 99
	when HHAdult > 0 then 1
	else 3 end 
from active_Household hhid

update an
set an.HHType = hhid.HHType
from active_Enrollment an
inner join active_Household hhid on hhid.HouseholdID = an.HouseholdID
/*************************************************************************
4.11 Get Active Clients for tmp_Person 
**********************************************************************/
delete from tmp_Person

insert into tmp_Person (PersonalID, HoHAdult, Age, LastActive, ReportID)
select distinct an.PersonalID
	--Ever served as an adult = 1...
	, max(case when an.AgeGroup between 18 and 65 then 1
		else 0 end) 
	--Plus ever served-as-HoH = 2 
	  + max(case when hhid.HoHID is null then 0
		else 2 end)
	--Equals:  0=Not HoH or Adult, 1=Adult, 2=HoH, 3=Both
	, min(an.AgeGroup)
	--LastActive date in report period is used for CH
	, max(case when an.ExitDate is null then rpt.ReportEnd else an.ExitDate end) 
	, rpt.ReportID
from lsa_Report rpt
inner join active_Enrollment an on an.EntryDate <= rpt.ReportEnd
left outer join active_Household hhid on hhid.HoHID = an.PersonalID
group by an.PersonalID, rpt.ReportID
/*************************************************************************
4.12 Set Demographic Values in tmp_Person 
**********************************************************************/
update lp
set 
	lp.Gender = case 
		when lp.HoHAdult = 0 then -1 
		when c.Gender in (8,9) then 98
		when c.Gender in (0,1,2) then c.Gender + 1
		when c.Gender in (3,4) then c.Gender
		else 99 end 
	, lp.Ethnicity = case 
		when lp.HoHAdult = 0 then -1 
		when c.Ethnicity in (8,9) then 98
		when c.Ethnicity in (0,1) then c.Ethnicity
		else 99 end 	
	, lp.Race = case 
		when lp.HoHAdult = 0 then -1 
		when c.RaceNone in (8,9) then 98
		when c.AmIndAkNative + Asian + BlackAfAmerican + 
			NativeHIOtherPacific + White > 1 then 6
		when White = 1 and c.Ethnicity = 1 then 1
		when White = 1 then 0
		when BlackAfAmerican = 1 then 2
		when Asian = 1 then 3
		when c.AmIndAkNative = 1 then 4
		when NativeHIOtherPacific = 1 then 5
		else 99 end 
	, lp.VetStatus = case 
		when lp.HoHAdult in (0, 2) then -1 
		when c.VeteranStatus in (8,9) then 98
		when c.VeteranStatus in (0,1) then c.VeteranStatus
		else 99 end 
	--To make it possible to select the minimum value 
	--from all associated Disability and DVStatus records --
	--i.e., select according to priority order -- 0 is 
	--selected as 97 in the subquery and reset to 0 here.
	, lp.DisabilityStatus = case 
		when lp.HoHAdult = 0 then -1
		when dis.dis = 97 then 0 
		else dis.dis end 	
	, lp.DVStatus = case  
		when lp.HoHAdult = 0 then -1
		when dv.DV = 97 then 0 
		when dv.DV is null then 99
		else dv.dv end 
from tmp_Person lp
inner join hmis_Client c on c.PersonalID = lp.PersonalID
inner join (select alldis.PersonalID, min(alldis.dis) as dis
				from (select distinct hn.PersonalID
					, case 
						when hn.DisablingCondition = 1 then 1
						when hn.DisablingCondition = 0 then 97
						else 99 end as dis
					from hmis_Enrollment hn
					inner join active_Enrollment ln 
						on ln.EnrollmentID = hn.EnrollmentID
					) alldis 
				group by alldis.PersonalID
				) dis on dis.PersonalID = lp.PersonalID
left outer join (select alldv.PersonalID, min(alldv.DV) as DV
				from 
					(select distinct hdv.PersonalID, case 
						when hdv.DomesticViolenceVictim = 1 
							and hdv.CurrentlyFleeing = 1 then 1
						when hdv.DomesticViolenceVictim = 1 
							and hdv.CurrentlyFleeing = 0 then 2
						when hdv.DomesticViolenceVictim = 1 
							and (hdv.CurrentlyFleeing is null or
							hdv.CurrentlyFleeing not in (0,1)) then 3
						when hdv.DomesticViolenceVictim = 0 then 97
						when hdv.DomesticViolenceVictim in (8,9) then 98
						else 99 end as DV
						from hmis_HealthAndDV hdv
						inner join active_Enrollment ln on
						  ln.EnrollmentID = hdv.EnrollmentID
					) alldv
				group by alldv.PersonalID) dv on dv.PersonalID = lp.PersonalID

/*************************************************************************
4.13 Get Chronic Homelessness Date Range for Each Head of Household/Adult
**********************************************************************/
--The three year period ending on a HoH/adult's last active date in the report
--period is relevant for determining chronic homelessness.  
--The start of the period is:
--  LastActive minus (3 years) plus (1 day)
update lp
set lp.CHStart = dateadd(dd, 1, (dateadd(yyyy, -3, lp.LastActive)))
from tmp_Person lp
where HoHAdult > 0

/*************************************************************************
4.14 Get Enrollments Relevant to Chronic Homelessness
**********************************************************************/
delete from ch_Enrollment

--NOTE regarding code methodology compared to specs document: 
--Enrollments in night-by-night shelters without bed night dates between CHStart 
--and LastActive are not relevant to CH.
--In this step, ALL enrollments with entry/exit dates that overlap the CH date range
--are inserted into ch_Enrollment, but StartDate and StopDate are set to NULL when 
--TrackingMethod = 3.
--In section 4.16, only dates with records of a bednight are included in ch_Time when 
--StartDate and StopDate are NULL, which effectively excludes any enrollment in a 
--night-by-night shelter without bednights. 
--This approach produces the same result without requiring a join to hmis_Services
--in both steps.

insert into ch_Enrollment(PersonalID, EnrollmentID, ProjectType
	, StartDate, MoveInDate, StopDate)
select distinct lp.PersonalID, hn.EnrollmentID, p.ProjectType
	, case 
		when p.TrackingMethod = 3 then null
		when hn.EntryDate < lp.CHStart then lp.CHStart 
		else hn.EntryDate end
	, case when p.ProjectType in (3,13) and hoh.MoveInDate >= hn.EntryDate 
		and hoh.MoveInDate < coalesce(x.ExitDate, lp.LastActive) 
		then hoh.MoveInDate else null end	
	, case 
		when p.TrackingMethod = 3 then null
		when x.ExitDate is null then lp.LastActive
		else x.ExitDate end
from tmp_Person lp
inner join lsa_Report rpt on rpt.ReportID = lp.ReportID
inner join hmis_Enrollment hn on hn.PersonalID = lp.PersonalID	
	and hn.EntryDate <= lp.LastActive
left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID 
	and x.ExitDate <= lp.LastActive 
inner join (select hhinfo.HouseholdID, min(hhinfo.MoveInDate) as MoveInDate
			, coc.CoCCode
		from hmis_Enrollment hhinfo
		inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
		group by hhinfo.HouseholdID, coc.CoCCode
	) hoh on hoh.HouseholdID = hn.HouseholdID and hoh.CoCCode = rpt.ReportCoC
inner join hmis_Project p on p.ProjectID = hn.ProjectID	
	and p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
where lp.HoHAdult > 0 
	and (x.ExitDate is null or x.ExitDate > lp.CHStart)
	
/*************************************************************************
4.15 Get Dates to Exclude from Counts of ES/SH/Street Days 
**********************************************************************/
delete from ch_Exclude

insert into ch_Exclude (PersonalID, excludeDate)
select distinct lp.PersonalID, cal.theDate
from tmp_Person lp
inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
inner join ref_Calendar cal on cal.theDate >=
		case when chn.ProjectType in (3,13) then chn.MoveInDate
		else chn.StartDate end
	and cal.theDate < chn.StopDate
where chn.ProjectType in (2,3,13)

/*************************************************************************
4.16 Get Dates to Include in Counts of ES/SH/Street Days 
**********************************************************************/
delete from ch_Time

--Dates enrolled in ES entry/exit or SH are counted if the
--client was not housed in RRH/PSH or enrolled in TH at the time.
insert into ch_Time (PersonalID, chDate)
select distinct lp.PersonalID, cal.theDate
from tmp_Person lp
inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
left outer join hmis_Services bn on bn.EnrollmentID = chn.EnrollmentID
	and bn.RecordType = 200 
	and bn.DateProvided between lp.CHStart and lp.LastActive
inner join ref_Calendar cal on 
	cal.theDate >= coalesce(chn.StartDate, bn.DateProvided)
	and cal.theDate < coalesce(chn.StopDate, dateadd(dd,1,bn.DateProvided))
left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
	and chx.PersonalID = chn.PersonalID
where chn.ProjectType in (1,8) and chx.excludeDate is null

--ESSHStreet dates from 3.917 collected for an EntryDate > CHStart
-- are counted if client was not housed in RRH/PSH or in TH at the time.
--For RRH/PSH, LivingSituation is assumed to extend to MoveInDate 
--or ExitDate (if there is no MoveInDate) and that time is also counted.
insert into ch_Time (PersonalID, chDate)
select distinct lp.PersonalID, cal.theDate
from tmp_Person lp
inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID 
	and hn.EntryDate > lp.CHStart
inner join ref_Calendar cal on 
	cal.theDate >= hn.DateToStreetESSH
	and cal.theDate < coalesce(chn.MoveInDate, chn.StopDate)
left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
	and chx.PersonalID = chn.PersonalID
left outer join ch_Time cht on cht.chDate = cal.theDate 
	and cht.PersonalID = chn.PersonalID
where chx.excludeDate is null
	and cht.chDate is null
	and (chn.ProjectType in (1,8)
		or hn.LivingSituation in (1,18,16)		
		or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
		or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
			and hn.LivingSituation in (4,5,6,7,15,24) ) 
		)

--Gaps of less than 7 nights between two ESSHStreet dates are counted
insert into ch_Time (PersonalID, chDate)
select gap.PersonalID, cal.theDate
from (select distinct s.PersonalID, s.chDate as StartDate, min(e.chDate) as EndDate
	from ch_Time s 
	inner join ch_Time e on e.PersonalID = s.PersonalID and e.chDate > s.chDate 
		and dateadd(dd, -7, e.chDate) <= s.chDate
	where s.PersonalID not in 
		(select PersonalID 
		from ch_Time 
		where chDate = dateadd(dd, 1, s.chDate))
	group by s.PersonalID, s.chDate) gap
inner join ref_Calendar cal on cal.theDate between gap.StartDate and gap.EndDate
left outer join ch_Time cht on cht.PersonalID = gap.PersonalID 
	and cht.chDate = cal.theDate
where cht.chDate is null

/*************************************************************************
4.17 Get ES/SH/Street Episodes
**********************************************************************/
delete from ch_Episodes

insert into ch_Episodes (PersonalID, episodeStart, episodeEnd)
select distinct s.PersonalID, s.chDate, min(e.chDate)
from ch_Time s 
--CHANGE 10/24/2018 'e.chDate > s.chDate' to >= for one day episodes
inner join ch_Time e on e.PersonalID = s.PersonalID  and e.chDate >= s.chDate
where s.PersonalID not in (select PersonalID from ch_Time where chDate = dateadd(dd, -1, s.chDate))
	and e.PersonalID not in (select PersonalID from ch_Time where chDate = dateadd(dd, 1, e.chDate))
group by s.PersonalID, s.chDate

update chep 
set episodeDays = datediff(dd, chep.episodeStart, chep.episodeEnd) + 1
from ch_Episodes chep

/*************************************************************************
4.18 Set Initial CHTime and CHTimeStatus Values
**********************************************************************/

update tmp_Person set CHTime = null, CHTimeStatus = null

update lp 
set CHTime = -1, CHTimeStatus = -1
from tmp_Person lp
where HoHAdult = 0

--Any client with a 365+ day episode that overlaps with their
--last year of activity
--will be reported as CH by the HDX (if DisabilityStatus = 1)
update lp 
set CHTime = 365, CHTimeStatus = 1
from tmp_Person lp
inner join ch_Episodes chep on chep.PersonalID = lp.PersonalID
	and chep.episodeDays >= 365
	and chep.episodeEnd between dateadd(dd, -364, lp.LastActive) and lp.LastActive
where HoHAdult > 0

--Episodes of 365+ days prior to the client's last year of activity must 
--be part of a series of at least four episodes in order to 
--meet time criteria for CH
update lp 
set CHTime = case 
		when ep.episodeDays >= 365 then 365
		when ep.episodeDays between 270 and 364 then 270
		else 0 end
	, CHTimeStatus = case
		when ep.episodes >= 4 then 2
		else 3 end
from tmp_Person lp
inner join (select chep.PersonalID
	, sum(chep.episodeDays) as episodeDays, count(distinct chep.episodeStart) as episodes
	from ch_Episodes chep 
	group by chep.PersonalID) ep on ep.PersonalID = lp.PersonalID
where HoHAdult > 0 and CHTime is null
/*************************************************************************
4.19 Update Selected CHTime and CHTimeStatus Values
**********************************************************************/
--Anyone not CH based on system use data + 3.917 date ranges
--will be counted as chronically homeless if any enrollment where 
--EntryDate is in the year ending on LastActive shows
--12 or more ESSHSTreet months and 4 or more times homeless
--(and DisabilityStatus = 1)
update lp 
set CHTime = 400
	, CHTimeStatus = 2
from tmp_Person lp
inner join ch_Enrollment cn on cn.PersonalID = lp.PersonalID
inner join hmis_Enrollment hn on hn.EnrollmentID = cn.EnrollmentID
	and hn.MonthsHomelessPastThreeYears in (112,113) 
	and hn.TimesHomelessPastThreeYears = 4
	and hn.EntryDate >= dateadd(dd, -364, lp.LastActive)
where 
	(HoHAdult > 0 and CHTime is null) or CHTime <> 365 or chTimeStatus = 3

--Anyone who doesn't meet CH time criteria and is missing data in 3.917 
--for an active enrollment should be identified as missing data.
update lp 
set CHTime = coalesce(lp.CHTime, 0)
	, CHTimeStatus = 99
from tmp_Person lp
inner join active_Enrollment an on an.PersonalID = lp.PersonalID
inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
	and ((hn.DateToStreetESSH > hn.EntryDate)
		or (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null)
		or (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null)
		or (an.ProjectType in (1,8) and (hn.DateToStreetESSH is null)) 
		or (hn.MonthsHomelessPastThreeYears in (8,9,99)) 
		or (hn.MonthsHomelessPastThreeYears is null) 
		or (hn.TimesHomelessPastThreeYears in (8,9,99))  
		or (hn.TimesHomelessPastThreeYears is null)
		or (hn.LivingSituation in (1,16,18) and hn.DateToStreetESSH is null)
		or (hn.LengthOfStay in (10,11) and ((hn.PreviousStreetESSH is null)
				or (hn.PreviousStreetESSH = 1 and hn.DateToStreetESSH is null)))
		or (hn.LivingSituation in (4,5,6,7,15,24) 
				and hn.LengthOfStay in (2,3)
				and ((hn.PreviousStreetESSH is NULL)
					or (hn.PreviousStreetESSH = 1 
						and hn.DateToStreetESSH is null))))
--CHANGE 10/24/2018 - align WHERE clause to specs (no change in output)
where (CHTime in (1,270) or CHTimeStatus = 3)
	and HoHAdult > 0

update tmp_Person 
set CHTime = 0, CHTimeStatus = -1
where HoHAdult > 0 and CHTime is null

/*************************************************************************
4.20 Set tmp_Person Project Group / Household Type Identifiers
**********************************************************************/
update tmp_Person 
set HHTypeEST = null, HHTypeRRH = null, HHTypePSH = null

--set EST HHType 
update lp
set lp.HHTypeEST = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for EST
				 (select distinct an.PersonalID
					, case when an.HHType = 1 then 100
						when an.HHType = 2 then 20
						when an.HHType = 3 then 3 
						else 0 end as HHTypeEach
					from active_Enrollment an 
					where an.ProjectType in (1,2,8)) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID

--set RRH HHType 
update lp
set lp.HHTypeRRH = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach
			) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for RRH
				 (select distinct an.PersonalID
					, case when an.HHType = 1 then 100
						when an.HHType = 2 then 20
						when an.HHType = 3 then 3 
						else 0 end as HHTypeEach
					from active_Enrollment an 
					where an.ProjectType = 13) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID

--set PSH HHType 
update lp
set lp.HHTypePSH = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for PSH
				 (select distinct an.PersonalID
					, case when an.HHType = 1 then 100
						when an.HHType = 2 then 20
						when an.HHType = 3 then 3 
						else 0 end as HHTypeEach
					from active_Enrollment an 
					where an.ProjectType = 3) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID


/*************************************************************************
4.21 Set tmp_Person Head of Household Identifiers for Each Project Group
**********************************************************************/
update tmp_Person 
set HoHEST = null, HoHRRH = null, HoHPSH = null

--set EST HHType 
update lp
set lp.HoHEST = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for EST
			(select distinct an.PersonalID
			, case when an.HHType = 1 then 100
				when an.HHType = 2 then 20
				when an.HHType = 3 then 3 
				else 0 end as HHTypeEach
			from active_Enrollment an 
			inner join active_Household hhid on hhid.HoHID = an.PersonalID
			where an.ProjectType in (1,2,8)) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID

--set RRH HHType 
update lp
set lp.HoHRRH = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach
			) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for RRH
			(select distinct an.PersonalID
			, case when an.HHType = 1 then 100
				when an.HHType = 2 then 20
				when an.HHType = 3 then 3 
				else 0 end as HHTypeEach
			from active_Enrollment an 
			inner join active_Household hhid on hhid.HoHID = an.PersonalID
			where an.ProjectType = 13) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID

--set PSH HHType 
update lp
set lp.HoHPSH = 
	case when hh.HHTypeCombined is null then -1
	else hh.HHTypeCombined end	
from tmp_Person lp
left outer join --Level 2 - combine HHTypes into a single value
	 (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach) 
			when 100 then 1
			when 120 then 12
			when 103 then 13
			when 20 then 2
			when 0 then 99
			else sum(HHTypes.HHTypeEach) end as HHTypeCombined
		from --Level 1 - get distinct HHTypes for PSH
			(select distinct an.PersonalID
			, case when an.HHType = 1 then 100
				when an.HHType = 2 then 20
				when an.HHType = 3 then 3 
				else 0 end as HHTypeEach
			from active_Enrollment an 
			inner join active_Household hhid on hhid.HoHID = an.PersonalID
			where an.ProjectType = 3) HHTypes  
		group by HHTypes.PersonalID
		) hh on hh.PersonalID = lp.PersonalID


/*************************************************************************
4.22 Set Population Identifiers for Active HouseholdIDs
**********************************************************************/

update ahh
set ahh.HHChronic = (select max(
				case when (n.AgeGroup not between 18 and 65 
					and n.PersonalID <> hh.HoHID)
					or lp.DisabilityStatus <> 1 
					or hh.HHType not in (1,2,3) then 0
				when (lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
					or (lp.CHTime = 400 and lp.CHTimeStatus = 2) then 1
				else 0 end)
		from tmp_Person lp
		inner join active_Enrollment n on n.PersonalID = lp.PersonalID
		inner join active_Household hh on hh.HouseholdID = n.HouseholdID
		where n.HouseholdID = ahh.HouseholdID)
	, ahh.HHVet = (select max(
				case when lp.VetStatus = 1 
					and n.AgeGroup between 18 and 65 
					and hh.HHType in (1,2) then 1
				else 0 end)
		from tmp_Person lp
		inner join active_Enrollment n on n.PersonalID = lp.PersonalID
		inner join active_Household hh on hh.HouseholdID = n.HouseholdID
		where n.HouseholdID = ahh.HouseholdID)
	, ahh.HHDisability = (select max(
			case when lp.DisabilityStatus = 1 
				and (n.AgeGroup between 18 and 65 
					or n.PersonalID = hh.HoHID) 
				and hh.HHType in (1,2,3) then 1
			else 0 end)
		from tmp_Person lp
		inner join active_Enrollment n on n.PersonalID = lp.PersonalID
		inner join active_Household hh on hh.HouseholdID = n.HouseholdID
		where n.HouseholdID = ahh.HouseholdID)
	, ahh.HHFleeingDV = (select max(
			case when lp.DVStatus = 1 
				and (n.AgeGroup between 18 and 65 
					or n.PersonalID = hh.HoHID) 
				and hh.HHType in (1,2,3) then 1
			else 0 end)
		from tmp_Person lp
		inner join active_Enrollment n on n.PersonalID = lp.PersonalID
		inner join active_Household hh on hh.HouseholdID = n.HouseholdID
		where n.HouseholdID = ahh.HouseholdID)
	--CHANGE 10/5/2018 - more corrections to HHAdultAge 
	, ahh.HHAdultAge = coalesce((select 
			--HHTypes 3 and 99 are excluded by the CASE statement
			case when max(n.AgeGroup) >= 98 then -1
					when max(n.AgeGroup) <= 17 then -1
					when min(n.AgeGroup) between 18 and 25 
						and max(n.AgeGroup) between 25 and 55 then 25
					when max(n.AgeGroup) = 21 then 18
					when max(n.AgeGroup) = 24 then 24
					when min(n.AgeGroup) between 64 and 65 then 55
					else -1 end
			from active_Enrollment n 
			where n.HouseholdID = ahh.HouseholdID and n.HHType in (1,2)), -1)
	, ahh.AC3Plus = (select case sum(case when n.AgeGroup <= 17 and hh.HHType = 2 then 1
							else 0 end) 
						when 0 then 0 
						when 1 then 0 
						when 2 then 0 
						else 1 end
			from active_Enrollment n 
			inner join active_Household hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = ahh.HouseholdID) 
from active_Household ahh

--CHANGE 9/28/2018 - 
-- HHParent was previously set in active_Household as a preliminary value
-- regardless of age group requirements, which were incorporated in setting
-- final values in tmp_Person and tmp_Household in 4.23 and 4.25.
-- This was creating confusion and not consistent with the order of operations 
-- in the specs. (No change to final LSA output.)
update ahh
set ahh.HHParent = (select max(
		case when n.RelationshipToHoH = 2 
			and n.AgeGroup <= 17  
			and (hh.HHType = 3 
				 or (hh.HHType = 2 and hh.HHAdultAge in (18,24))) then 1  
			else 0 end)
	from active_Enrollment n 
	inner join active_Household hh on hh.HouseholdID = n.HouseholdID
	where n.HouseholdID = ahh.HouseholdID)
from active_Household ahh

/*************************************************************************
4.23 Set tmp_Person Population Identifiers from Active Households
**********************************************************************/
update lp
	--CHANGE 10/23/2018 - correction to pull HHAdultAge from active_Household
	-- and not from active_Enrollment (github issue #23).
set lp.HHAdultAge = coalesce((select case when min(hh.HHAdultAge) between 18 and 24
			then min(hh.HHAdultAge) 
		else max(hh.HHAdultAge) end
		from active_Enrollment n 
		inner join active_Household hh on hh.HouseholdID = n.HouseholdID
			and ((hh.HHType = 1 and hh.HHAdultAge between 18 and 55) 
				or (hh.HHType = 2 and hh.HHAdultAge between 18 and 24))
		where n.PersonalID = lp.PersonalID), -1)
   , lp.AC3Plus = (select max(hhid.AC3Plus) 
		from active_Household hhid
		inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
		where n.PersonalID = lp.PersonalID)
   , lp.HHChronic = case popHHTypes.HHChronic
		when '0' then -1
		else convert(int,replace(popHHTypes.HHChronic, '0', '')) end
   , lp.HHVet = case popHHTypes.HHVet
		when '0' then -1
		else convert(int,replace(popHHTypes.HHVet, '0', '')) end
   , lp.HHDisability = case popHHTypes.HHDisability
		when '0' then -1
		else convert(int,replace(popHHTypes.HHDisability, '0', '')) end
   , lp.HHFleeingDV = case popHHTypes.HHFleeingDV
		when '0' then -1
		else convert(int,replace(popHHTypes.HHFleeingDV, '0', '')) end
   , lp.HHParent = case popHHTypes.HHParent
		when '0' then -1
		else convert(int,replace(popHHTypes.HHParent, '0', '')) end
from tmp_Person lp
inner join (select distinct lp.PersonalID
		, HHChronic = (select convert(varchar(3),sum(distinct
				case when hhid.HHChronic = 0 then 0
					when hhid.HHType = 1 then 100
					when hhid.HHType = 2 then 20
					when hhid.HHType = 3 then 3 
					else 0 end))
			from active_Household hhid
			inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
			where n.PersonalID = lp.PersonalID)
		, HHVet = (select convert(varchar(3),sum(distinct
				case when hhid.HHVet = 0 then 0 
					when hhid.HHType = 1 then 100
					when hhid.HHType = 2 then 20
					else 0 end))
			from active_Household hhid
			inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
			where n.PersonalID = lp.PersonalID)
		, HHDisability = (select convert(varchar(3),sum(distinct
				case when hhid.HHDisability = 0 then 0
					when hhid.HHType = 1 then 100
					when hhid.HHType = 2 then 20
					when hhid.HHType = 3 then 3 
					else 0 end))
			from active_Household hhid
			inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
			where n.PersonalID = lp.PersonalID)
		, HHFleeingDV = (select convert(varchar(3),sum(distinct
				case when hhid.HHFleeingDV = 0 then 0
					when hhid.HHType = 1 then 100
					--CHANGE 9/28/2018 delete HHAdultAge in (18,24) and move to HHParent where it belongs
					when hhid.HHType = 2 then 20
					when hhid.HHType = 3 then 3 
					else 0 end))
			from active_Household hhid
			inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
			where n.PersonalID = lp.PersonalID)
		, HHParent = (select convert(varchar(3),sum(distinct
				case when hhid.HHParent = 0 then 0
					--CHANGE 9/28/2018 - add HHAdultAge in (18,24)
					when hhid.HHType = 2 and hhid.HHAdultAge in (18,24) then 20
					when hhid.HHType = 3 then 3 
					else 0 end))
			from active_Household hhid
			inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
			where n.PersonalID = lp.PersonalID)
		from tmp_Person lp
) popHHTypes on popHHTypes.PersonalID = lp.PersonalID


/*************************************************************************
4.24-25 Get Unique Households and Population Identifiers for tmp_Household
**********************************************************************/
delete from tmp_Household

insert into tmp_Household (HoHID, HHType
	, HHChronic, HHVet, HHDisability, HHFleeingDV
	, HoHRace, HoHEthnicity
	, HHParent, ReportID, FirstEntry, LastActive)
select distinct hhid.HoHID, hhid.HHType
	, max(hhid.HHChronic)
	, max(hhid.HHVet)
	, max(hhid.HHDisability)
	, max(hhid.HHFleeingDV)
	, lp.Race, lp.Ethnicity
	, max(case when hhid.HHParent <> 1 then 0
			when hhid.HHType = 2 and hhid.HHAdultAge not in (18,24) then 0
			else hhid.HHParent end)
	, lp.ReportID
	, min(an.EntryDate)
	, max(coalesce(an.ExitDate, rpt.ReportEnd)) 
from active_Household hhid
inner join active_Enrollment an on an.HouseholdID = hhid.HouseholdID
	and an.PersonalID = hhid.HoHID
inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
inner join tmp_Person lp on lp.PersonalID = hhid.HoHID 
group by hhid.HoHID, hhid.HHType, lp.Race, lp.Ethnicity
	, lp.ReportID

update hh
set HHChild = (select case when count(distinct n.PersonalID) >= 3 then 3
				else count(distinct n.PersonalID) end
			from active_Household hhid
			inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
			where n.AgeGroup < 18
			and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID)
	, HHAdult = (select case when count(distinct n.PersonalID) >= 3 then 3
				else count(distinct n.PersonalID) end
			from active_Household hhid
			inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
			where n.AgeGroup between 18 and 65 
				and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID
				and n.PersonalID not in 
					--subquery for 
					(select n17.PersonalID 
					 from active_Household hh17
					 --CHANGE join n17.HouseholdID = hh17.HouseholdID (not hhid)
					 inner join active_Enrollment n17 on n17.HouseholdID = hh17.HouseholdID
					 where hh17.HoHID = hhid.HoHID and hh17.HHType = hhid.HHType
						and n17.AgeGroup < 18))
	, HHNoDOB = (select case when count(distinct n.PersonalID) >= 3 then 3
				else count(distinct n.PersonalID) end
		from active_Household hhid
		inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
		where n.AgeGroup > 65
			and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID)
from tmp_Household hh

update hh
set hh.HHAdultAge = coalesce ((select case 
				when min(hhid.HHAdultAge) in (18,24) 
					then min(hhid.HHAdultAge)
				when max(hhid.HHAdultAge) = 55 then 55
				else 25 end
			from active_Household hhid
			where hhid.HHAdultAge between 18 and 55
				and hhid.HoHID = hh.HoHID and hhid.HHType = hh.HHType), -1)
from tmp_Household hh

--CHANGE 10/5/2018 - general cleanup for any HHAdultAge not set 
update hh
set hh.HHAdultAge = -1
from tmp_Household hh
where hh.HHAdultAge is null


/*************************************************************************
4.26 Set tmp_Household Project Group Status Indicators

NOTE 10/5/2018 - The programming specs specify that households should 
be counted as active at ReportEnd if ExitDate is > ReportEnd or is NULL.

As populated in step 4.8, active_Enrollment.ExitDate 
is NULL unless it is <= ReportEnd.  Because the sample code is pulling 
ExitDate info from active_Enrollment, confirmation that an ExitDate 
is in report period is not illustrated here. 
**********************************************************************/

update hh
set ESTStatus = coalesce ((select 
		min(case when an.ExitDate is null then 1
			else 2 end) 
		from active_Enrollment an 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType in (1,2,8)), 0)
from tmp_Household hh

update hh
set ESTStatus = ESTStatus + (select 
		min(case when an.EntryDate < rpt.ReportStart then 10
			else 20 end) 
		from active_Enrollment an
		inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType in (1,2,8))
from tmp_Household hh
where ESTStatus > 0

update hh
set RRHStatus = coalesce ((select 
		min(case when an.ExitDate is null then 1
			else 2 end) 
		from active_Enrollment an 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType = 13), 0)
from tmp_Household hh

update hh
set RRHStatus = RRHStatus + (select 
		min(case when an.EntryDate < rpt.ReportStart then 10
			else 20 end) 
		from active_Enrollment an
		inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType = 13)
from tmp_Household hh
where RRHStatus > 0

update hh
set PSHStatus = coalesce ((select 
		min(case when an.ExitDate is null then 1
			else 2 end) 
		from active_Enrollment an 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType = 3), 0)
from tmp_Household hh

update hh
set PSHStatus = PSHStatus + (select 
		min(case when an.EntryDate < rpt.ReportStart then 10
			else 20 end) 
		from active_Enrollment an
		inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate 
		where an.PersonalID = hh.HoHID
			and hh.HHType = an.HHType and an.RelationshipToHoH = 1
		and an.ProjectType = 3)
from tmp_Household hh
where PSHStatus > 0
/*************************************************************************
4.27 Set tmp_Household RRH and PSH Move-In Status Indicators
**********************************************************************/
--CHANGE 10/23/2018 - To align with specs where household has multiple RRH/PSH
-- enrollments, updated so status is preferentially based on MoveInDate in 
-- report period (top priority), MoveInDate prior to ReportStart (2nd),
-- or no MoveInDate (lowest).
update hh
set hh.RRHMoveIn = case when hh.RRHStatus = 0 then -1
		when stat.RRHMoveIn = 10 then 1
		else stat.RRHMoveIn end
	, hh.PSHMoveIn = case when hh.PSHStatus = 0 then -1
		when stat.PSHMoveIn = 10 then 1
		else stat.PSHMoveIn end
from tmp_Household hh
left outer join (select distinct hhid.HoHID, hhid.HHType
		, RRHMoveIn = (select max(case when an.MoveInDate is null
				then 0
				when an.MoveInDate >= rpt.ReportStart then 10
				else 2 end)
			from active_Enrollment an 
			inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
			where an.PersonalID = hhid.HoHID 
				and an.HouseholdID = hhid.HouseholdID
				and hhid.ProjectType = 13)
		, PSHMoveIn = (select max(case when an.MoveInDate is null
				then 0
				when an.MoveInDate >= rpt.ReportStart then 10
				else 2 end)
			from active_Enrollment an 
			inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
			where an.PersonalID = hhid.HoHID 
				and an.HouseholdID = hhid.HouseholdID
				and hhid.ProjectType = 3)			
	from active_Household hhid) stat on 
		stat.HoHID = hh.HoHID and stat.HHType = hh.HHType

/*************************************************************************
4.28.a Get Most Recent Enrollment in Each ProjectGroup for HoH 
***********************************************************************/
update active_Enrollment set MostRecent = null

update an
set an.MostRecent =
	case when mr.EnrollmentID is null then 1
	else 0 end 
from active_Enrollment an
left outer join (select later.PersonalID, later.EnrollmentID
		, later.EntryDate, later.HHType
		, case when later.ProjectType in (1,2,8) then 1
			else later.ProjectType end as PT
	from active_Enrollment later
	where later.RelationshipToHoH = 1
	) mr on mr.PersonalID = an.PersonalID 
		and mr.HHType = an.HHType 
		and mr.PT = case when an.ProjectType in (1,2,8) then 1 else an.ProjectType end
		and (mr.EntryDate > an.EntryDate 
			or (mr.EntryDate = an.EntryDate and mr.EnrollmentID > an.EnrollmentID))
where an.RelationshipToHoH = 1 

/*************************************************************************
4.28.b Set tmp_Household Geography for Each Project Group 
**********************************************************************/
update lhh
set ESTGeography = -1 
from tmp_Household lhh
where ESTStatus <= 10

update lhh
set ESTGeography = coalesce(
	(select top 1 lg.GeographyType
	from active_Enrollment an 
	inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
	where an.MostRecent = 1 and an.ProjectType in (1,2,8)
		and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
		and an.HHType = lhh.HHType
	order by lg.InformationDate desc), 99)
from tmp_Household lhh where ESTGeography is null

update lhh
set RRHGeography = -1 
from tmp_Household lhh
where RRHStatus <= 10

update lhh
set RRHGeography = coalesce(
	(select top 1 lg.GeographyType
	from active_Enrollment an 
	inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
	where an.MostRecent = 1 and an.ProjectType = 13
		and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
		and an.HHType = lhh.HHType
	order by lg.InformationDate desc), 99)
from tmp_Household lhh where RRHGeography is null

update lhh
set PSHGeography = -1 
from tmp_Household lhh
where PSHStatus <= 10

update lhh
set PSHGeography = coalesce(
	(select top 1 lg.GeographyType
	from active_Enrollment an 
	inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
	where an.MostRecent = 1 and an.ProjectType = 3
		and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
		and an.HHType = lhh.HHType
	order by lg.InformationDate desc), 99)
from tmp_Household lhh where PSHGeography is null

/*************************************************************************
4.28.c Set tmp_Household Living Situation for Each Project Group 
**********************************************************************/
--UPDATE 10/22/2018 - populate Living Situation based on EARLIEST active  
-- enrollment in project group (and NOT most recent active enrollment) 

update lhh
set lhh.ESTLivingSit = -1 
from tmp_Household lhh
where lhh.ESTStatus <= 10

update lhh
set lhh.ESTLivingSit = 
	case when hn.LivingSituation = 16 then 1 --Homeless - Street
		when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
		when hn.LivingSituation = 27 then 3	--Interim Housing
		when hn.LivingSituation = 2 then 4	--Homeless - TH
		when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
		when hn.LivingSituation = 26 then 6	--Residential project
		when hn.LivingSituation = 12 then 7	--Family		
		when hn.LivingSituation = 13 then 8	--Friends
		when hn.LivingSituation = 3 then 9	--PSH
		when hn.LivingSituation in (21,23) then 10	--PH - own
		when hn.LivingSituation = 22 then 11	--PH - rent no subsidy
		when hn.LivingSituation in (19,20,25) then 12	--PH - rent with subsidy
		when hn.LivingSituation = 15 then 13	--Foster care
		when hn.LivingSituation = 24 then 14	--Long-term care
		when hn.LivingSituation = 7 then 15	--Institutions - incarceration
		when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
		else 99	end
from tmp_Household lhh
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
where lhh.ESTLivingSit is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
		 from active_Enrollment an
		 where an.ProjectType in (1,2,8) 
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.EntryDate asc)

update lhh
set lhh.RRHLivingSit = -1 
from tmp_Household lhh
where lhh.RRHStatus <= 10

update lhh
set lhh.RRHLivingSit = 
	case when hn.LivingSituation = 16 then 1 --Homeless - Street
		when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
		when hn.LivingSituation = 27 then 3	--Interim Housing
		when hn.LivingSituation = 2 then 4	--Homeless - TH
		when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
		when hn.LivingSituation = 26 then 6	--Residential project
		when hn.LivingSituation = 12 then 7	--Family		
		when hn.LivingSituation = 13 then 8	--Friends
		when hn.LivingSituation = 3 then 9	--PSH
		when hn.LivingSituation in (21,23) then 10	--PH - own
		when hn.LivingSituation = 22 then 11	--PH - rent no subsidy
		when hn.LivingSituation in (19,20,25) then 12	--PH - rent with subsidy
		when hn.LivingSituation = 15 then 13	--Foster care
		when hn.LivingSituation = 24 then 14	--Long-term care
		when hn.LivingSituation = 7 then 15	--Institutions - incarceration
		when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
		else 99	end
from tmp_Household lhh
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
where lhh.RRHLivingSit is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
		 from active_Enrollment an
		 where an.ProjectType = 13 
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.EntryDate asc)
update lhh
set lhh.PSHLivingSit = -1 
from tmp_Household lhh
where lhh.PSHStatus <= 10

update lhh
set lhh.PSHLivingSit = 
	case when hn.LivingSituation = 16 then 1 --Homeless - Street
		when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
		when hn.LivingSituation = 27 then 3	--Interim Housing
		when hn.LivingSituation = 2 then 4	--Homeless - TH
		when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
		when hn.LivingSituation = 26 then 6	--Residential project
		when hn.LivingSituation = 12 then 7	--Family		
		when hn.LivingSituation = 13 then 8	--Friends
		when hn.LivingSituation = 3 then 9	--PSH
		when hn.LivingSituation in (21,23) then 10	--PH - own
		when hn.LivingSituation = 22 then 11	--PH - rent no subsidy
		when hn.LivingSituation in (19,20,25) then 12	--PH - rent with subsidy
		when hn.LivingSituation = 15 then 13	--Foster care
		when hn.LivingSituation = 24 then 14	--Long-term care
		when hn.LivingSituation = 7 then 15	--Institutions - incarceration
		when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
		else 99	end
from tmp_Household lhh
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
where lhh.PSHLivingSit is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
		 from active_Enrollment an
		 where an.ProjectType = 3 
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.EntryDate asc)

/*************************************************************************
4.28.d Set tmp_Household Destination for Each Project Group 
**********************************************************************/
--CHANGE 10/23/2018 - populate EST/RRH/PSHDestination based on most recent EXIT  
-- from project group (and NOT exit for enrollment with most recent entry date)  
update lhh
set ESTDestination = -1 
from tmp_Household lhh
where ESTStatus not in (12,22)

update lhh
set ESTDestination = 
	case when hx.Destination = 3 then 1 --PSH
	 when hx.Destination = 31 then 2	--PH - rent/temp subsidy
	 when hx.Destination in (19,20,21,26,28) then 3	--PH - rent/own with subsidy
	 when hx.Destination in (10,11) then 4	--PH - rent/own no subsidy
	 when hx.Destination = 22 then 5	--Family - perm
	 when hx.Destination = 23 then 6	--Friends - perm
	 when hx.Destination in (15,25) then 7	--Institutions - group/assisted
	 when hx.Destination in (4,5,6) then 8	--Institutions - medical
	 when hx.Destination = 7 then 9	--Institutions - incarceration
	 when hx.Destination in (14,29) then 10	--Temporary - not homeless
	 when hx.Destination in (1,2,18,27) then 11	--Homeless - ES/SH/TH
	 when hx.Destination = 16 then 12	--Homeless - Street
	 when hx.Destination = 12 then 13	--Family - temp
	 when hx.Destination = 13 then 14	--Friends - temp
	 when hx.Destination = 24 then 15	--Deceased
	 else 99	end
from tmp_Household lhh 
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
where lhh.ESTDestination is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
from active_Enrollment an 
		 where an.ProjectType in (1,2,8) 
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.ExitDate desc)
	
update lhh
set RRHDestination = -1 
from tmp_Household lhh
where RRHStatus not in (12,22)

update lhh
set RRHDestination = 
	case when hx.Destination = 3 then 1 --PSH
	 when hx.Destination = 31 then 2	--PH - rent/temp subsidy
	 when hx.Destination in (19,20,21,26,28) then 3	--PH - rent/own with subsidy
	 when hx.Destination in (10,11) then 4	--PH - rent/own no subsidy
	 when hx.Destination = 22 then 5	--Family - perm
	 when hx.Destination = 23 then 6	--Friends - perm
	 when hx.Destination in (15,25) then 7	--Institutions - group/assisted
	 when hx.Destination in (4,5,6) then 8	--Institutions - medical
	 when hx.Destination = 7 then 9	--Institutions - incarceration
	 when hx.Destination in (14,29) then 10	--Temporary - not homeless
	 when hx.Destination in (1,2,18,27) then 11	--Homeless - ES/SH/TH
	 when hx.Destination = 16 then 12	--Homeless - Street
	 when hx.Destination = 12 then 13	--Family - temp
	 when hx.Destination = 13 then 14	--Friends - temp
	 when hx.Destination = 24 then 15	--Deceased
	 else 99	end
from tmp_Household lhh 
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
where lhh.RRHDestination is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
from active_Enrollment an 
		 where an.ProjectType = 13
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.ExitDate desc)

update lhh
set PSHDestination = -1 
from tmp_Household lhh
where PSHStatus not in (12,22)

update lhh
set PSHDestination = 
	case when hx.Destination = 3 then 1 --PSH
	 when hx.Destination = 31 then 2	--PH - rent/temp subsidy
	 when hx.Destination in (19,20,21,26,28) then 3	--PH - rent/own with subsidy
	 when hx.Destination in (10,11) then 4	--PH - rent/own no subsidy
	 when hx.Destination = 22 then 5	--Family - perm
	 when hx.Destination = 23 then 6	--Friends - perm
	 when hx.Destination in (15,25) then 7	--Institutions - group/assisted
	 when hx.Destination in (4,5,6) then 8	--Institutions - medical
	 when hx.Destination = 7 then 9	--Institutions - incarceration
	 when hx.Destination in (14,29) then 10	--Temporary - not homeless
	 when hx.Destination in (1,2,18,27) then 11	--Homeless - ES/SH/TH
	 when hx.Destination = 16 then 12	--Homeless - Street
	 when hx.Destination = 12 then 13	--Family - temp
	 when hx.Destination = 13 then 14	--Friends - temp
	 when hx.Destination = 24 then 15	--Deceased
	 else 99	end
from tmp_Household lhh 
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
where lhh.PSHDestination is null 
	and hn.EnrollmentID in 
		(select top 1 an.EnrollmentID 
from active_Enrollment an 
		 --CHANGE 10/24/2018 correct project type to 3 (was 13)
		 where an.ProjectType = 3
			and an.PersonalID = lhh.HoHID
			and an.RelationshipToHoH = 1
			and an.HHType = lhh.HHType
		 order by an.ExitDate desc)

/*************************************************************************
4.29.a Get Earliest EntryDate from Active Enrollments 
**********************************************************************/
update lhh
set lhh.FirstEntry = (select min(an.EntryDate)
	from active_Enrollment an
	where an.PersonalID = lhh.HoHID and an.HHType = lhh.HHType)
from tmp_Household lhh


/*************************************************************************
4.29.b Get EnrollmentID for Latest Exit in Two Years Prior to FirstEntry
**********************************************************************/
select hhid.HouseholdID
  , case
  when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
  when sum(hhid.AgeStatus/100) > 0 then 99
  when sum(hhid.AgeStatus%10) > 0 then 3
  when sum((hhid.AgeStatus/10)%100) > 0 then 1
  else 99 end as HHType
  into #hh
from
  --get AgeStatus for household members on previous enrollment
  (select distinct hn.HouseholdID
    , case when c.DOBDataQuality in (8,9)
      or c.DOB is null
      or c.DOB = '1/1/1900'
      or c.DOB > hn.EntryDate
      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
      --age for non-active enrollments is always based on EntryDate
      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
      or c.DOBDataQuality is null
      or c.DOBDataQuality not in (1,2) then 100
    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
    else 1 end as AgeStatus
  from hmis_Enrollment hn
  inner join hmis_Client c on c.PersonalID = hn.PersonalID
  inner join --get project type and CoC info for prior enrollments
      (select distinct hhinfo.HouseholdID
      from hmis_Enrollment hhinfo
      inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
      inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
      inner join hmis_EnrollmentCoC coc on
        coc.EnrollmentID = hhinfo.EnrollmentID
        and coc.CoCCode = rpt.ReportCoC
      where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
          group by hhinfo.HouseholdID, coc.CoCCode
          ) hoh on hoh.HouseholdID = hn.HouseholdID
      group by hn.HouseholdID
      , case when c.DOBDataQuality in (8,9)
          or c.DOB is null
          or c.DOB = '1/1/1900'
          or c.DOB > hn.EntryDate
          or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
          --age for non-active enrollments is always based on EntryDate
          or dateadd(yy, 105, c.DOB) <= hn.EntryDate
          or c.DOBDataQuality is null
          or c.DOBDataQuality not in (1,2) then 100
        when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
        else 1 end
      ) hhid
    group by hhid.HouseholdID

CREATE NONCLUSTERED INDEX ix_hh_household_id ON #hh (HouseholdID);
CREATE NONCLUSTERED INDEX ix_hh_hhtype ON #hh (HHType);

update lhh
set lhh.StatEnrollmentID =
  (select top 1 prior.EnrollmentID
  from hmis_Enrollment prior
  inner join hmis_Exit hx on hx.EnrollmentID = prior.EnrollmentID
    and hx.ExitDate > prior.EntryDate
    and hx.ExitDate between dateadd(dd,-730,lhh.FirstEntry) and lhh.FirstEntry
  inner join --Get enrollments for the same HoH and HHType prior to FirstEntry
    #hh on #hh.HouseholdID = prior.HouseholdID
    where prior.PersonalID = lhh.HoHID and prior.RelationshipToHoH = 1
        and #hh.HHType = lhh.HHType
    order by hx.ExitDate desc)
from tmp_Household lhh

drop table #hh

/*************************************************************************
4.29.c Set System Engagement Status for tmp_Household
**********************************************************************/
update lhh
set lhh.Stat = case 
	when PSHStatus in (11,12) or RRHStatus in (11,12) or ESTStatus in (11,12)
		then 5
	when lhh.StatEnrollmentID is null then 1
	when dateadd(dd, 15, hx.ExitDate) >= lhh.FirstEntry then 5 
	when hx.Destination in (3,31,19,20,21,26,28,10,11,22,23) then 2
	when hx.Destination in (15,25,4,5,6,7,14,29,1,2,18,27,16,12,13) then 3
	else 4 end  
from tmp_Household lhh
left outer join hmis_Exit hx on hx.EnrollmentID = lhh.StatEnrollmentID

/*************************************************************************
4.29.d Set ReturnTime for tmp_Household
**********************************************************************/
update lhh
set lhh.ReturnTime = case
	when lhh.Stat in (1, 5) then -1 
	else datediff(dd, hx.ExitDate, lhh.FirstEntry) end
from tmp_Household lhh
left outer join hmis_Exit hx on hx.EnrollmentID = lhh.StatEnrollmentID

/*****************************************************************
4.30 Get Days In RRH Pre-Move-In
*****************************************************************/
update lhh
set RRHPreMoveInDays = case when RRHStatus < 10 then -1 
	else (select count(distinct cal.theDate)
		from tmp_Person lp
		inner join lsa_Report rpt on rpt.ReportID = lp.ReportID
		inner join active_Enrollment an on an.PersonalID = lp.PersonalID
		inner join ref_Calendar cal on cal.theDate >= an.EntryDate
			and cal.theDate <= coalesce(
					  dateadd(dd, -1, an.MoveInDate)
					, dateadd(dd, -1, an.ExitDate)
					, rpt.ReportEnd)
		where an.ProjectType = 13 and an.HHType = lhh.HHType 
			and lp.PersonalID = lhh.HoHID) end
from tmp_Household lhh

/*****************************************************************
4.31 Get Dates Housed in PSH or RRH
*****************************************************************/
delete from sys_Time

insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct an.PersonalID, an.HHType, cal.theDate
	, min(case an.ProjectType
			when 3 then 1
			else 2 end)
from tmp_Person lp
inner join active_Enrollment an on an.PersonalID = lp.PersonalID
	and an.RelationshipToHoH = 1
inner join ref_Calendar cal on cal.theDate >= an.MoveInDate
	and (cal.theDate < an.ExitDate 
			or (an.ExitDate is null and cal.theDate <= lp.LastActive))
where an.ProjectType in (3,13)
group by an.PersonalID, an.HHType, cal.theDate
/*****************************************************************
4.32 Get Enrollments Relevant to Last Inactive Date and Other System Use Days

NOTE 10/5/2018 - The INSERT includes both active and potentially relevant
     inactive enrollments.
*****************************************************************/
delete from sys_Enrollment

insert into sys_Enrollment (HoHID, HHType, EnrollmentID, ProjectType
	, EntryDate
	, MoveInDate
	, ExitDate
	, Active)
select distinct hn.PersonalID
	-- CHANGE 10/23/2018 for active enrollments, use HHType as already calculated; 
	-- otherwise, use HHType based on HH member age(s) at project entry.
	, case when an.EnrollmentID is not null then an.HHType else hh.HHType end
	, hn.EnrollmentID, p.ProjectType
	, case when p.TrackingMethod = 3 then null else hn.EntryDate end
	, case when p.ProjectType in (3,13) then hn.MoveInDate else null end
	, case when p.TrackingMethod = 3 then null else hx.ExitDate end
	, case when an.EnrollmentID is not null then 1 else 0 end
from tmp_Household lhh
inner join lsa_Report rpt on rpt.ReportID = lhh.ReportID
inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
	and hn.RelationshipToHoH = 1
left outer join active_Enrollment an on an.EnrollmentID = hn.EnrollmentID
left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
	and hx.ExitDate <= rpt.ReportEnd
inner join hmis_Project p on p.ProjectID = hn.ProjectID
inner join (select hhid.HouseholdID, case	
	    --if at least 1 adult and 1 child, HHType = 2
		when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 
			then 2
		--If not adult/child, any unknown age means HHType = 99
		when sum(hhid.AgeStatus/100) > 0 
			then 99
		--child only HHType = 3
		when sum(hhid.AgeStatus%10) > 0 
			then 3
		--adult only HHType = 1
		when sum((hhid.AgeStatus/10)%100) > 0
			then 1
		else 99 end as HHType
		from (select distinct hn.HouseholdID
			, case when c.DOBDataQuality in (8,9) 
					or c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > hn.EntryDate
					or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
					or dateadd(yy, 105, c.DOB) <= hn.EntryDate 
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 100
				when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
				else 1 end as AgeStatus
			from hmis_Enrollment hn
			inner join hmis_Client c on c.PersonalID = hn.PersonalID
			inner join (select distinct hhinfo.HouseholdID
					from hmis_Enrollment hhinfo
					inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
					inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
					inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
						and coc.CoCCode = rpt.ReportCoC
					where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
					) hoh on hoh.HouseholdID = hn.HouseholdID
			) hhid
		group by hhid.HouseholdID
		) hh on hh.HouseholdID = hn.HouseholdID
where 
	an.EnrollmentID is not null --All active enrollments are relevant.
	or (hx.ExitDate >= '10/1/2012'-- Inactive enrollments potentially relevant...
	    	and hh.HHType = lhh.HHType -- if they occurred under the same HHType
		and lhh.Stat = 5 --... and HH was 'continously engaged' at ReportStart...
		and lhh.PSHMoveIn <> 2) --...and HH was not housed in PSH at ReportStart.
/*****************************************************************
4.33 Get Last Inactive Date
*****************************************************************/
select distinct sn.HoHID as HoHID
  , sn.HHType as HHType
  , bn.DateProvided as StartDate
  , case when bn.DateProvided < rpt.ReportStart
    then dateadd(dd,6,bn.DateProvided)
    else rpt.ReportEnd end as EndDate
into #padded
from sys_Enrollment sn
inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
  and bn.RecordType = 200
inner join lsa_Report rpt on rpt.ReportEnd >= bn.DateProvided
where sn.EntryDate is null
union select sn.HoHID, sn.HHType, sn.EntryDate
  , case when sn.ExitDate < rpt.ReportStart
    then dateadd(dd,6,sn.ExitDate)
    else rpt.ReportEnd end
from sys_Enrollment sn
inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
where sn.ProjectType in (1,8,2) or sn.MoveInDate is null

CREATE NONCLUSTERED INDEX ix_padded_HoHID ON #padded (HoHID);
CREATE NONCLUSTERED INDEX ix_padded_HHType ON #padded (HHType);
CREATE NONCLUSTERED INDEX ix_padded_StartDate ON #padded (StartDate);
CREATE NONCLUSTERED INDEX ix_padded_EndDate ON #padded (EndDate);

update lhh
set lhh.LastInactive = coalesce(lastDay.inactive, '9/30/2012')
from tmp_Household lhh
left outer join (select lhh.HoHID, lhh.HHType, max(cal.theDate) as inactive
  from tmp_Household lhh
  inner join lsa_Report rpt on rpt.ReportID = lhh.ReportID
  inner join ref_Calendar cal on cal.theDate <= rpt.ReportEnd
    and cal.theDate >= '10/1/2012'
  left outer join
     #padded on #padded.HoHID = lhh.HoHID and #padded.HHType = lhh.HHType
      and cal.theDate between #padded.StartDate and #padded.EndDate
  where #padded.HoHID is null
    and cal.theDate < lhh.FirstEntry
group by lhh.HoHID, lhh.HHType
  ) lastDay on lastDay.HoHID = lhh.HoHID and lastDay.HHType = lhh.HHType

drop table #padded;
 
/*****************************************************************
4.34 Get Dates of Other System Use
*****************************************************************/
--Transitional Housing (sys_Time.sysStatus = 3)
insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct sn.HoHID, sn.HHType, cal.theDate, 3
from sys_Enrollment sn
inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
inner join ref_Calendar cal on 
	cal.theDate >= sn.EntryDate
	and cal.theDate > lhh.LastInactive
	and cal.theDate < coalesce(sn.ExitDate, rpt.ReportEnd)
left outer join sys_Time housed on housed.HoHID = sn.HoHID and housed.HHType = sn.HHType
	and housed.sysDate = cal.theDate
where housed.sysDate is null and sn.ProjectType = 2

--Emergency Shelter (Entry/Exit) (sys_Time.sysStatus = 4)
insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct sn.HoHID, sn.HHType, cal.theDate, 4
from sys_Enrollment sn
inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
inner join ref_Calendar cal on 
	cal.theDate >= sn.EntryDate
	and cal.theDate < coalesce(sn.ExitDate, rpt.ReportEnd)
left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
	and other.sysDate = cal.theDate
where (cal.theDate > lhh.LastInactive)
	and other.sysDate is null and sn.ProjectType = 1

--Emergency Shelter (Night-by-Night) (sys_Time.sysStatus = 4)
insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct sn.HoHID, sn.HHType, cal.theDate, 4
from sys_Enrollment sn
inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
	and bn.RecordType = 200
inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
inner join lsa_Report rpt on rpt.ReportEnd >= bn.DateProvided 
inner join ref_Calendar cal on cal.theDate = bn.DateProvided
left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
	and other.sysDate = cal.theDate
where (cal.theDate > lhh.LastInactive)
	and other.sysDate is null and sn.ProjectType = 1

--Homeless (Time prior to Move-In) in PSH or RRH (sys_Time.sysStatus = 5 or 6)
insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct sn.HoHID, sn.HHType, cal.theDate
	, min (case when sn.ProjectType = 3 then 5 else 6 end)
from sys_Enrollment sn
inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
inner join ref_Calendar cal on 
	cal.theDate >= sn.EntryDate
	and cal.theDate < coalesce(sn.MoveInDate, sn.ExitDate, rpt.ReportEnd)
left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
	and other.sysDate = cal.theDate
where cal.theDate > lhh.LastInactive
	and other.sysDate is null and sn.ProjectType in (3,13)
group by sn.HoHID, sn.HHType, cal.theDate
/*****************************************************************
4.35 Get Other Dates Homeless from 3.917 Living Situation
*****************************************************************/
--If there are enrollments in sys_Enrollment where EntryDate >= LastInactive,
-- dates between the earliest DateToStreetESSH and LastInactive --
-- i.e., dates without a potential status conflict based on other system use --
-- populate Other3917Days as the difference in days between DateToStreetESSH
-- and LastInactive + 1. 

--NOTE:  This statement will leave Other3917Days NULL for households without
--at least one DateToStreetESSH prior to LastInactive.  Final value for Other3917Days
--is the sum of days prior to LastInactive (if any) PLUS the count of dates 
--added to sys_Time in the next statement.  It is set in 4.36.
update lhh
set lhh.Other3917Days = (select datediff (dd,
		(select top 1 hn.DateToStreetESSH
		from sys_Enrollment sn 
		inner join hmis_Enrollment hn on hn.EnrollmentID = sn.EnrollmentID
		where sn.HHType = lhh.HHType  
			and sn.HoHID = lhh.HoHID 
			and dateadd(dd, 1, lhh.LastInactive) between hn.DateToStreetESSH and hn.EntryDate
		order by hn.DateToStreetESSH asc)
	, lhh.LastInactive))
from tmp_Household lhh


insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
select distinct sn.HoHID, sn.HHType, cal.theDate, 7
from sys_Enrollment sn
inner join hmis_Enrollment hn on hn.EnrollmentID = sn.EnrollmentID 
inner join sys_Time contiguous on contiguous.sysDate = hn.EntryDate
	and contiguous.HoHID = sn.HoHID and contiguous.HHType = sn.HHType
inner join ref_Calendar cal on cal.theDate >= hn.DateToStreetESSH
	and cal.theDate < hn.EntryDate
left outer join sys_Time st on st.HoHID = sn.HoHID and st.HHType = sn.HHType
	and st.sysDate = cal.theDate
where st.sysDate is null
	and (sn.ProjectType in (1,8)
	or hn.LivingSituation in (1,18,16)
	or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
	or (hn.LivingSituation in (4,5,6,7,15,24) 
		and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
/*****************************************************************
4.36 Set System Use Days for LSAHousehold
*****************************************************************/
update lhh
set ESDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus = 4
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, THDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus = 3
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, ESTDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus in (3,4)
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, RRHPSHPreMoveInDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus in (5,6)
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, RRHHousedDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus = 2
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, SystemDaysNotPSHHoused = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus in (2,3,4,5,6)
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, SystemHomelessDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus in (3,4,5,6)
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, Other3917Days = case 
			when Other3917Days is null then 0 
			else Other3917Days end + (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus = 7
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, TotalHomelessDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus in (3,4,5,6,7)
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
	, PSHHousedDays = (select count(distinct st.sysDate)
		from sys_Time st 
		where st.sysStatus = 1
		and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
from tmp_Household lhh

--Set counts of days in project type to -1 for households with no
--active enrollment in the relevant project type.  
update lhh
set lhh.ESDays = -1 
from tmp_Household lhh
where lhh.ESDays = 0 and lhh.ESTStatus = 0

update lhh
set lhh.THDays = -1 
from tmp_Household lhh
where lhh.THDays = 0 and lhh.ESTStatus = 0

update lhh
set lhh.ESTDays = -1 
from tmp_Household lhh
where lhh.ESDays = -1 and lhh.THDays = -1

update lhh
set lhh.RRHPSHPreMoveInDays = -1
from tmp_Household lhh
where lhh.RRHPSHPreMoveInDays = 0 
	and lhh.RRHStatus = 0 and lhh.PSHStatus = 0

update lhh
set lhh.RRHHousedDays = -1
from tmp_Household lhh
where lhh.RRHHousedDays = 0 and lhh.RRHStatus = 0

update lhh
set lhh.PSHHousedDays = -1
from tmp_Household lhh
where lhh.PSHHousedDays = 0 and lhh.PSHStatus = 0

/*****************************************************************
4.37 Update ESTStatus and RRHStatus
*****************************************************************/
--CHANGE 10/23/2018 - for both UPDATE statements, join to sys_Time
-- and align methodology with specs (github issue #24)

update lhh
set lhh.ESTStatus = 2
from tmp_Household lhh
inner join sys_Time st on st.HoHID = lhh.HoHID and st.HHType = lhh.HHType
where lhh.ESTStatus = 0 
	and st.sysStatus in (3,4) 

update lhh
set lhh.RRHStatus = 2
from tmp_Household lhh
inner join sys_Time st on st.HoHID = lhh.HoHID and st.HHType = lhh.HHType
where lhh.RRHStatus = 0 
	and st.sysStatus = 6

/*****************************************************************
4.38 Set SystemPath for LSAHousehold
*****************************************************************/
--CHANGE 10/23/2018 use 'ESTStatus = 0' instead of 'ESDays <= 0 and THDays <= 0' 
-- for SystemPath 4, 8, and 11 (no impact on output; modified for consistency with specs).
-- (issue #23)
update lhh
set lhh.SystemPath = 
	case when lhh.ESTStatus not in (21,22) and lhh.RRHStatus not in (21,22) and lhh.PSHMoveIn = 2 
		then -1
	when lhh.ESDays >= 1 and lhh.THDays <= 0 and lhh.RRHStatus = 0 and lhh.PSHStatus = 0 
		then 1
	when lhh.ESDays <= 0 and lhh.THDays >= 1 and lhh.RRHStatus = 0 and lhh.PSHStatus = 0 
		then 2
	when lhh.ESDays >= 1 and lhh.THDays >= 1 and lhh.RRHStatus = 0 and lhh.PSHStatus = 0 
		then 3
	when lhh.ESTStatus = 0 and lhh.RRHStatus >= 2 and lhh.PSHStatus = 0 
		then 4
	when lhh.ESDays >= 1 and lhh.THDays <= 0 and lhh.RRHStatus >= 2 and lhh.PSHStatus = 0 
		then 5
	when lhh.ESDays <= 0 and lhh.THDays >= 1 and lhh.RRHStatus >= 2 and lhh.PSHStatus = 0 
		then 6
	when lhh.ESDays >= 1 and lhh.THDays >= 1 and lhh.RRHStatus >= 2 and lhh.PSHStatus = 0 
		then 7
	when lhh.ESTStatus = 0 and lhh.RRHStatus = 0 and lhh.PSHStatus >= 11 and lhh.PSHMoveIn <> 2
		then 8
	when lhh.ESDays >= 1 and lhh.THDays <= 0 and lhh.RRHStatus = 0 and lhh.PSHStatus >= 11 and lhh.PSHMoveIn <> 2
		then 9
	when lhh.ESDays >= 1 and lhh.THDays <= 0 and lhh.RRHStatus >= 2 and lhh.PSHStatus >= 11 and lhh.PSHMoveIn <> 2
		then 10
	when lhh.ESTStatus = 0 and lhh.RRHStatus >= 2 and lhh.PSHStatus >= 11 and lhh.PSHMoveIn <> 2
		then 11
	else 12 end
from tmp_Household lhh

/*****************************************************************
4.39 Get Exit Cohort Dates
*****************************************************************/
delete from tmp_CohortDates

insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
select 0, rpt.ReportStart,
	case when dateadd(mm, -6, rpt.ReportEnd) <= rpt.ReportStart 
		then rpt.ReportEnd
		else dateadd(mm, -6, rpt.ReportEnd) end
from lsa_Report rpt

insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
select -1, dateadd(yyyy, -1, rpt.ReportStart)
	, dateadd(yyyy, -1, rpt.ReportEnd)
from lsa_Report rpt

insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
select -2, dateadd(yyyy, -2, rpt.ReportStart)
	, dateadd(yyyy, -2, rpt.ReportEnd)
from lsa_Report rpt

/*****************************************************************
4.40 Get Exit Cohort Members and Enrollments
*****************************************************************/
delete from ex_Enrollment 

insert into ex_Enrollment (Cohort, HoHID, HHType, EnrollmentID, ProjectType
   , EntryDate, MoveInDate, ExitDate, ExitTo)
select distinct cd.Cohort, hn.PersonalID, hh.HHType, hn.EnrollmentID, p.ProjectType 
   , hn.EntryDate, hn.MoveInDate, hx.ExitDate 
   , case when hx.Destination = 3 then 1 --PSH
	 when hx.Destination = 31 then 2	--PH - rent/temp subsidy
	 when hx.Destination in (19,20,21,26,28) then 3	--PH - rent/own with subsidy
	 when hx.Destination in (10,11) then 4	--PH - rent/own no subsidy
	 when hx.Destination = 22 then 5	--Family - perm
	 when hx.Destination = 23 then 6	--Friends - perm
	 when hx.Destination in (15,25) then 7	--Institutions - group/assisted
	 when hx.Destination in (4,5,6) then 8	--Institutions - medical
	 when hx.Destination = 7 then 9	--Institutions - incarceration
	 when hx.Destination in (14,29) then 10	--Temporary - not homeless
	 when hx.Destination in (1,2,18,27) then 11	--Homeless - ES/SH/TH
	 when hx.Destination = 16 then 12	--Homeless - Street
	 when hx.Destination = 12 then 13	--Family - temp
	 when hx.Destination = 13 then 14	--Friends - temp
	 when hx.Destination = 24 then 15	--Deceased
	 else 99	end
from hmis_Enrollment hn
inner join hmis_Project p on p.ProjectID = hn.ProjectID
inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
	and hx.ExitDate > hn.EntryDate
inner join tmp_CohortDates cd on cd.CohortStart <= hx.ExitDate 
	and cd.CohortEnd >= hx.ExitDate 
inner join 
		--hh identifies household exits by HHType from relevant projects
		--and adds HHType their HHType  
		(select hhid.HouseholdID, case
			when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
			when sum(hhid.AgeStatus/100) > 0 then 99
			when sum(hhid.AgeStatus%10) > 0 then 3
			when sum((hhid.AgeStatus/10)%100) > 0 then 1
			else 99 end as HHType
		from (--hhid identifies age status (adult/child/unknown) for 
			  --members of households with exits in subquery hoh
			select distinct hn.HouseholdID
			, case when c.DOBDataQuality in (8,9) 
					or c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > hn.EntryDate
					or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
					or ((hn.EntryDate >= cd.CohortStart 
						and dateadd(yy, 105, c.DOB) <= hn.EntryDate) 
							or (dateadd(yy, 105, c.DOB) <= cd.CohortStart))
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 100
				--calculate age for qualifying exit as of 
				--the later of CohortStart and EntryDate
				when hn.EntryDate >= cd.CohortStart 
					and dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
				when dateadd(yy, 18, c.DOB) <= cd.CohortStart then 10 
				else 1 end as AgeStatus
			from hmis_Enrollment hn
			inner join tmp_CohortDates cd on cd.CohortEnd >= hn.EntryDate
			inner join hmis_Client c on c.PersonalID = hn.PersonalID
			inner join 
					--hoh identifies exits for heads of household
					--from relevant projects in cohort periods
					(select distinct hhinfo.HouseholdID
					from hmis_Enrollment hhinfo
					inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
					inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
					left outer join lsa_Project lp on lp.ProjectID = p.ProjectID	
					inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
						and coc.CoCCode = rpt.ReportCoC
					--Project type for qualifying exit MAY BE STREET OUTREACH
					--in addition to ES/SH/TH/RRH/PSH when LSAScope = 1 (systemwide).					
					--  When LSAScope = 2 (project-focused), the project must have a record 
					--  in lsa_Project
					where p.ProjectType in (1,2,3,4,8,13) and p.ContinuumProject = 1
							and (rpt.LSAScope = 1 or lp.ProjectID is not NULL)
					group by hhinfo.HouseholdID
					) hoh on hoh.HouseholdID = hn.HouseholdID
			group by hn.HouseholdID
			, case when c.DOBDataQuality in (8,9) 
					or c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > hn.EntryDate
					or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
					or ((hn.EntryDate >= cd.CohortStart 
						and dateadd(yy, 105, c.DOB) <= hn.EntryDate) 
							or (dateadd(yy, 105, c.DOB) <= cd.CohortStart))
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 100
				--calculate age for qualifying exit as of 
				--the later of CohortStart and EntryDate
				when hn.EntryDate >= cd.CohortStart 
					and dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
				when dateadd(yy, 18, c.DOB) <= cd.CohortStart then 10 
				else 1 end
			) hhid
		group by hhid.HouseholdID
		) hh on hh.HouseholdID = hn.HouseholdID
left outer join 
		--Subquery b identifies household enrollments by HHType in ES/SH/TH/RRH/PSH 
		--  projects active in the cohort period; if these include any activity in the 
		--  within 15 days of an exit identified in the hh subquery, the hh exit is 
		--  excluded in the WHERE clause.
		(select hn.PersonalID as HoHID, hh.HHType, hn.EntryDate, hx.ExitDate
		from hmis_Enrollment hn
		left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
		inner join (select hhid.HouseholdID, case	
					when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
					when sum(hhid.AgeStatus/100) > 0 then 99
					when sum(hhid.AgeStatus%10) > 0 then 3
					when sum((hhid.AgeStatus/10)%100) > 0 then 1
					else 99 end as HHType
				from (select distinct hn.HouseholdID
					, case when c.DOBDataQuality in (8,9) 
							or c.DOB is null 
							or c.DOB = '1/1/1900'
							or c.DOB > hn.EntryDate
							or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
							or dateadd(yy, 105, c.DOB) <= hn.EntryDate 
							or c.DOBDataQuality is null
							or c.DOBDataQuality not in (1,2) then 100
						when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
						else 1 end as AgeStatus
						from hmis_Enrollment hn
						inner join hmis_Client c on c.PersonalID = hn.PersonalID
						inner join (select distinct hhinfo.HouseholdID
								from hmis_Enrollment hhinfo
								inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
								inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
								inner join hmis_EnrollmentCoC coc on 
									coc.EnrollmentID = hhinfo.EnrollmentID
									and coc.CoCCode = rpt.ReportCoC
								--only ES/SH/TH/RRH/PSH enrollments are relevant
								where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
								group by hhinfo.HouseholdID, coc.CoCCode
								) hoh on hoh.HouseholdID = hn.HouseholdID
						group by hn.HouseholdID
						, case when c.DOBDataQuality in (8,9) 
								or c.DOB is null 
								or c.DOB = '1/1/1900'
								or c.DOB > hn.EntryDate
								or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
								or dateadd(yy, 105, c.DOB) <= hn.EntryDate 
								or c.DOBDataQuality is null
								or c.DOBDataQuality not in (1,2) then 100
							when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
							else 1 end
						)  hhid
					group by hhid.HouseholdID
					) hh on hh.HouseholdID = hn.HouseholdID
				where hn.RelationshipToHoH = 1
				) b on b.HoHID = hn.PersonalID and b.HHType = hh.HHType
					and b.EntryDate < dateadd(dd, 15, hx.ExitDate) 
					and (b.ExitDate is NULL or b.ExitDate > hx.ExitDate)
--If there is at least one exit followed by 15 days of inactivity during a cohort period,
--the HoHID/HHType is included in the relevant exit cohort.
where hn.RelationshipToHoH = 1 and b.HoHID is null and cd.Cohort <= 0


/*****************************************************************
4.41 Get EnrollmentIDs for Exit Cohort Households

       and

4.42 Set ExitFrom and ExitTo for Exit Cohort Households
*****************************************************************/
update ex
set ex.Active = 1 
from ex_Enrollment ex
where ex.EnrollmentID = (select top 1 EnrollmentID 
              from ex_Enrollment a 
              where a.HoHID = ex.HoHID and a.HHType = ex.HHType
                      and a.Cohort = ex.Cohort
              order by case when a.ExitTo between 1 and 6 then 2
                      when a.ExitTo between 7 and 14 then 3
                      else 4 end asc, a.ExitDate asc)

delete from tmp_Exit

insert into tmp_Exit (Cohort, HoHID, HHType
       , EnrollmentID, ex.EntryDate, ex.ExitDate, ExitFrom, ExitTo)
select distinct ex.Cohort, ex.HoHID, ex.HHType
       , ex.EnrollmentID, ex.EntryDate, ex.ExitDate
       , case ex.ProjectType 
              when 4 then 1
              when 1 then 2
              when 2 then 3 
              when 8 then 4
              when 13 then 5
              else 6 end
       , ex.ExitTo
from ex_Enrollment ex
where ex.Active = 1

update tmp_Exit
set ReportID = (select ReportID 
              from lsa_Report)
/*****************************************************************
4.43 Set ReturnTime for Exit Cohort Households
*****************************************************************/

select hhid.HouseholdID, case
when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
when sum(hhid.AgeStatus/100) > 0 then 99
when sum(hhid.AgeStatus%10) > 0 then 3
when sum((hhid.AgeStatus/10)%100) > 0 then 1
else 99 end as HHType
into #hh
from (select distinct hn.HouseholdID
  , case when c.DOBDataQuality in (8,9)
      or c.DOB is null
      or c.DOB = '1/1/1900'
      or c.DOB > hn.EntryDate
      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
      --age for later enrollments is always based on EntryDate
      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
      or c.DOBDataQuality is null
      or c.DOBDataQuality not in (1,2) then 100
    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
    else 1 end as AgeStatus
  from hmis_Enrollment hn
  inner join hmis_Client c on c.PersonalID = hn.PersonalID
  inner join (select distinct hhinfo.HouseholdID
      from hmis_Enrollment hhinfo
      inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
      inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
      inner join hmis_EnrollmentCoC coc on
        coc.EnrollmentID = hhinfo.EnrollmentID
        and coc.CoCCode = rpt.ReportCoC
      --only later ES/SH/TH/RRH/PSH enrollments are relevant
      where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
      group by hhinfo.HouseholdID, coc.CoCCode
      ) hoh on hoh.HouseholdID = hn.HouseholdID
  group by hn.HouseholdID
  , case when c.DOBDataQuality in (8,9)
      or c.DOB is null
      or c.DOB = '1/1/1900'
      or c.DOB > hn.EntryDate
      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
      --age for later enrollments is always based on EntryDate
      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
      or c.DOBDataQuality is null
      or c.DOBDataQuality not in (1,2) then 100
    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
    else 1 end
  ) hhid
group by hhid.HouseholdID

CREATE NONCLUSTERED INDEX ix_household_id ON #hh (HouseholdID);
CREATE NONCLUSTERED INDEX ix_hhtype ON #hh (HHType);

update ex
set ex.ReturnDate = (select min(hn.EntryDate)
    from hmis_Enrollment hn
    inner join #hh on #hh.HouseholdID = hn.HouseholdID
        where hn.RelationshipToHoH = 1
          and hn.PersonalID = ex.HoHID and #hh.HHType = ex.HHType
          and hn.EntryDate
            between dateadd(dd, 15, ex.ExitDate) and dateadd(dd, 730, ex.ExitDate))
from tmp_Exit ex

drop table #hh;

update ex
set ex.ReturnTime =
  case when ex.ReturnDate is null then -1
    else datediff(dd, ex.ExitDate, ex.ReturnDate) end
from tmp_Exit ex
/*****************************************************************
4.44 Set Population Identifiers for Exit Cohort Households
*****************************************************************/
update ex
set ex.HoHRace = case 
		when c.RaceNone in (8,9) then 98
		when c.AmIndAkNative + c.Asian + c.BlackAfAmerican + 
			 c.NativeHIOtherPacific + c.White > 1 then 6
		when c.White = 1 and c.Ethnicity = 1 then 1
		when c.White = 1 then 0
		when c.BlackAfAmerican = 1 then 2
		when c.Asian = 1 then 3
		when c.AmIndAkNative = 1 then 4
		when c.NativeHIOtherPacific = 1 then 5
		else 99 end 
	, ex.HoHEthnicity = case 
		when c.Ethnicity in (8,9) then 98
		when c.Ethnicity in (0,1) then c.Ethnicity
		else 99 end 	
from tmp_Exit ex
inner join hmis_Client c on c.PersonalID = ex.HoHID 


update ex
set ex.HHVet = pop.HHVet
	, ex.HHDisability = pop.HHDisability
	, ex.HHFleeingDV = pop.HHFleeingDV
	, ex.HHParent = case when ex.HHType in (2,3)
		then pop.HHParent else 0 end
	, ex.AC3Plus = case when ex.HHType = 2 
		and pop.HHChild >= 3 then 1 else 0 end 
from tmp_Exit ex
inner join (
	select ex.EnrollmentID
		, max(case when age.ageStat = 1 and c.VeteranStatus = 1 then 1 
			else 0 end) as HHVet
		, max(case when (age.ageStat = 1 or hn.RelationshipToHoH = 1)
				and hn.DisablingCondition = 1 then 1
			else 0 end) as HHDisability
		, max(case when (age.ageStat = 1 or hn.RelationshipToHoH = 1)
				and dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 1 then 1 
			else 0 end) as HHFleeingDV
		, sum(case when age.ageStat = 0 then 1 
			else 0 end) as HHChild
		-- NOTE:  HHParent value is preliminary -- it is reset to 0 for AC
		--  households with adults over 24 at the end of this section.
		--  CHANGE 10/15/2018 - child of HoH must be < 18 to set HHParent = 1
		, max(case when hn.RelationshipToHoH = 2 and age.ageStat = 0 then 1
			else 0 end) as HHParent
	from tmp_Exit ex
	inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
	inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
	inner join hmis_Client c on c.PersonalID = hn.PersonalID
	left outer join hmis_HealthAndDV dv on hn.EnrollmentID = dv.EnrollmentID
	inner join (select distinct hn.PersonalID
		, case when c.DOBDataQuality in (8,9) then -1
			when c.DOB is null 
				or c.DOB = '1/1/1900'
				or c.DOB > hn.EntryDate
				or (hn.RelationshipToHoH = 1 and c.DOB = hn.EntryDate)
				or DATEADD(yy, 105, c.DOB) <= hn.EntryDate 
				or c.DOBDataQuality is null
				or c.DOBDataQuality not in (1,2) then -1 
			when hn.EntryDate >= cd.CohortStart 
				and DATEADD(yy, 18, c.DOB) <= hn.EntryDate then 1
			when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 1
			else 0 end as ageStat
		from tmp_Exit ex
		inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
		inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
		inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
		inner join hmis_Client c on c.PersonalID = hn.PersonalID
		) age on age.PersonalID = hn.PersonalID
	group by ex.EnrollmentID) pop on pop.EnrollmentID = ex.EnrollmentID

update ex
set ex.HHAdultAge = ageGroup.AgeGroup
from 
tmp_Exit ex
inner join 
	(select adultAges.HoHID, adultAges.EnrollmentID
		, case when max(adultAges.AgeGroup) = 99 then -1
			when max(adultAges.AgeGroup) = 18 then 18
			when max(adultAges.AgeGroup) = 24 then 24
			when min(adultAges.AgeGroup) = 55 then 55
			when min(adultAges.AgeGroup) < 55
				and max(adultAges.AgeGroup) > 24 then 25
	 		--CHANGE 10/23/2018 set to -1 vs NULL as default
			else -1 end as AgeGroup
	from (select distinct ex.HoHID, hoh.EnrollmentID 
			, case when c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > hn.EntryDate
					or (hn.RelationshipToHoH = 1 and c.DOB = hn.EntryDate)
					or DATEADD(yy, 105, c.DOB) <= hn.EntryDate 
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 99 
				when hn.EntryDate >= cd.CohortStart 
					and DATEADD(yy, 55, c.DOB) <= hn.EntryDate then 55
				when hn.EntryDate >= cd.CohortStart 
					and DATEADD(yy, 25, c.DOB) <= hn.EntryDate then 25
				when hn.EntryDate >= cd.CohortStart 
					and DATEADD(yy, 22, c.DOB) <= hn.EntryDate then 24
				when hn.EntryDate >= cd.CohortStart 
					and DATEADD(yy, 18, c.DOB) <= hn.EntryDate then 18
				when DATEADD(yy, 55, c.DOB) <= cd.CohortStart then 55
				when DATEADD(yy, 25, c.DOB) <= cd.CohortStart then 25
				when DATEADD(yy, 22, c.DOB) <= cd.CohortStart then 24
				when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 18
				else NULL end as AgeGroup
			from tmp_Exit ex
			inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
			inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
			inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
			inner join hmis_Client c on c.PersonalID = hn.PersonalID
			) adultAges
	group by adultAges.HoHID, adultAges.EnrollmentID 
		) ageGroup on ageGroup.EnrollmentID = ex.EnrollmentID
			and (ex.HHType = 1 
				or (ex.HHType = 2 and ageGroup between 18 and 24))

update ex
set ex.HHAdultAge = -1 
from tmp_Exit ex
where ex.HHAdultAge is null

update ex
set ex.HHParent = 0 
from tmp_Exit ex
where ex.HHParent = 1 and ex.HHAdultAge not in (18,24)

/*****************************************************************
4.45 Set Stat for Exit Cohort Households
*****************************************************************/
select hhid.HouseholdID, case
  when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
  when sum(hhid.AgeStatus/100) > 0 then 99
  when sum(hhid.AgeStatus%10) > 0 then 3
  when sum((hhid.AgeStatus/10)%100) > 0 then 1
  else 99 end as HHType
into #hh
from
  --HouseholdIDs with age status for household members
  (select distinct hn.HouseholdID
  , case when c.DOBDataQuality in (8,9)
      or c.DOB is null
      or c.DOB = '1/1/1900'
      or c.DOB > hn.EntryDate
      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
      --age for prior enrollments is always based on EntryDate
      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
      or c.DOBDataQuality is null
      or c.DOBDataQuality not in (1,2) then 100
    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
    else 1 end as AgeStatus
  from hmis_Enrollment hn
  inner join hmis_Client c on c.PersonalID = hn.PersonalID
  inner join
      --HouseholdIDs
      (select distinct hhinfo.HouseholdID
      from hmis_Enrollment hhinfo
      inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
      inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
      inner join hmis_EnrollmentCoC coc on
        coc.EnrollmentID = hhinfo.EnrollmentID
        and coc.CoCCode = rpt.ReportCoC
      where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
          group by hhinfo.HouseholdID, coc.CoCCode
          ) hoh on hoh.HouseholdID = hn.HouseholdID
      ) hhid
  group by hhid.HouseholdID

CREATE NONCLUSTERED INDEX ix_household_id ON #hh (HouseholdID);
CREATE NONCLUSTERED INDEX ix_hhtype ON #hh (HHType);

update ex
set ex.StatEnrollmentID = (select top 1 previous.EnrollmentID
  from hmis_Enrollment previous
  inner join hmis_Exit hx on hx.EnrollmentID = previous.EnrollmentID
    and hx.ExitDate > previous.EntryDate
    and dateadd(dd,730,hx.ExitDate) >= ex.EntryDate
    and hx.ExitDate < ex.ExitDate
  inner join
    --HouseholdIDs with LSA household types
    #hh on #hh.HouseholdID = previous.HouseholdID
      where previous.PersonalID = ex.HoHID and previous.RelationshipToHoH = 1
        and #hh.HHType = ex.HHType
      order by hx.ExitDate desc)
from tmp_Exit ex

drop table #hh;

update ex
set ex.Stat = case when ex.StatEnrollmentID is null then 1
  when dateadd(dd, 15, hx.ExitDate) >= ex.EntryDate then 5
  when hx.Destination in (3,31,19,20,21,26,28,10,11,22,23) then 2
  when hx.Destination in (15,25,4,5,6,7,14,29,1,2,18,27,16,12,13) then 3
  else 4 end
from tmp_Exit ex
left outer join hmis_Exit hx on hx.EnrollmentID = ex.StatEnrollmentID
/*****************************************************************
4.46 Get Other Enrollments Relevant to Exit Cohort System Path
*****************************************************************/
delete from sys_Enrollment
insert into sys_Enrollment (HoHID, HHType, EnrollmentID, ProjectType
	, EntryDate
	, MoveInDate
	, ExitDate
	, Active)
select distinct hn.PersonalID
	--CHANGE 10/22/2018 use HHType as already calculated for qualifying exit; 
	-- otherwise, use HHType based on HH member age(s) at project entry.
	, case when ex.EnrollmentID = hn.EnrollmentID then ex.HHType else hh.HHType end
	, hn.EnrollmentID, p.ProjectType
	, case when p.TrackingMethod = 3 then null else hn.EntryDate end
	, case when p.ProjectType in (3,13) then hn.MoveInDate else null end
	, case when p.TrackingMethod = 3 then null else hx.ExitDate end
	--CHANGE 10/15/2018 to use MAX - enrollments were being inserted multiple
	--times
	, max(case when hn.EnrollmentID = ex.EnrollmentID then 1 else 0 end)
from tmp_Exit ex
inner join hmis_Enrollment hn on hn.PersonalID = ex.HoHID
	and hn.RelationshipToHoH = 1
inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
	and hx.ExitDate <= ex.ExitDate
inner join hmis_Project p on p.ProjectID = hn.ProjectID
inner join 
		--HouseholdIDs with LSA household types
		(select hhid.HouseholdID, case	
			when sum(hhid.AgeStatus%10) > 0 and sum((hhid.AgeStatus/10)%100) > 0 then 2
			when sum(hhid.AgeStatus/100) > 0 then 99
			when sum(hhid.AgeStatus%10) > 0 then 3
			when sum((hhid.AgeStatus/10)%100) > 0 then 1
			else 99 end as HHType
		from (select distinct hn.HouseholdID
			, case when c.DOBDataQuality in (8,9) 
					or c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > hn.EntryDate
					or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
					or dateadd(yy, 105, c.DOB) <= hn.EntryDate 
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 100
				when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10 
				else 1 end as AgeStatus
			from hmis_Enrollment hn
			inner join hmis_Client c on c.PersonalID = hn.PersonalID
			inner join (select distinct hhinfo.HouseholdID
					from hmis_Enrollment hhinfo
					inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
					inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
					inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
						and coc.CoCCode = rpt.ReportCoC
					where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
					group by hhinfo.HouseholdID, coc.CoCCode
					) hoh on hoh.HouseholdID = hn.HouseholdID
			) hhid
		group by hhid.HouseholdID
		) hh on hh.HouseholdID = hn.HouseholdID
--CHANGE 10/24/2018 - limit inserts to enrollments where the HHType as calculated by the subquery 
--  matches tmp_Exit HHType OR the enrollment is associated with the qualifying exit. (issue #28)
where hh.HHType = ex.HHType or hn.EnrollmentID = ex.EnrollmentID
group by hn.PersonalID
	, case when ex.EnrollmentID = hn.EnrollmentID then ex.HHType else hh.HHType end
	, hn.EnrollmentID, p.ProjectType
	, case when p.TrackingMethod = 3 then null else hn.EntryDate end
	, case when p.ProjectType in (3,13) then hn.MoveInDate else null end
	, case when p.TrackingMethod = 3 then null else hx.ExitDate end

update ex
set ex.LastInactive = lastDay.inactive
from tmp_Exit ex
inner join (select ex.Cohort, ex.HoHID, ex.HHType, max(cal.theDate) as inactive
	from tmp_Exit ex
	inner join ref_Calendar cal on cal.theDate < ex.EntryDate
	left outer join	
		--bednights
		(select distinct sn.HoHID 
			, sn.HHType as HHType
			, x.Cohort 
			, bn.DateProvided as StartDate
			, dateadd(dd,6,bn.DateProvided) as EndDate
		from sys_Enrollment sn
		inner join tmp_Exit x on x.HHType = sn.HHType and x.HoHID = sn.HoHID
			and x.ExitDate >= sn.ExitDate
		inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
			and bn.RecordType = 200
		where sn.EntryDate is null
		union 
		--time in ES/SH/TH or in RRH/PSH but not housed
		select sn.HoHID, sn.HHType, x.Cohort, sn.EntryDate
			, dateadd(dd,6,sn.ExitDate)
		from sys_Enrollment sn 
		inner join tmp_Exit x on x.HHType = sn.HHType and x.HoHID = sn.HoHID
			and x.ExitDate >= sn.ExitDate
		where sn.ProjectType in (1,8,2) or sn.MoveInDate is null
		) padded on padded.HoHID = ex.HoHID and padded.HHType = ex.HHType 
			and cal.theDate between padded.StartDate and padded.EndDate
	where padded.HoHID is null
	group by ex.HoHID, ex.HHType, ex.Cohort
	) lastDay on lastDay.HoHID = ex.HoHID and lastDay.HHType = ex.HHType
		and lastDay.Cohort = ex.Cohort
/*****************************************************************
4.46 Set SystemPath for Exit Cohort Households
*****************************************************************/
-- SystemPath n/a for:
-- - Any household exiting after 365+ days housed in RRH/PSH
-- - Any household housed in PSH before CohortStart
update ex
set ex.SystemPath = -1 
from tmp_Exit ex 
inner join hmis_Enrollment hn on hn.EnrollmentID = ex.EnrollmentID
inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
where (dateadd(dd, 365, hn.MoveInDate) <= ex.ExitDate
		and ex.ExitFrom in (5,6))
	 or (ex.ExitFrom = 6 and hn.MoveInDate < cd.CohortStart)

-- SystemPath can be set directly based on ExitFrom for
-- -Any household exiting from street outreach (ExitFrom = 1)
-- -Any first time homeless household (Stat = 1)
-- -Any household returning/re-engaging after 15-730 days (Stat in (2,3,4))
update ex
set ex.SystemPath = case 
	when ex.ExitFrom = 1 then 12
	when ex.ExitFrom = 2 then 1
	when ex.ExitFrom = 3 then 2
	when ex.ExitFrom = 4 then 1
	when ex.ExitFrom = 5 then 4
	when ex.ExitFrom = 6 then 8
	else 8 end
from tmp_Exit ex 
inner join sys_Enrollment sn on sn.EnrollmentID = ex.EnrollmentID
inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
where ex.SystemPath is null
	and ex.Stat in (1,2,3,4) or ex.ExitFrom = 1

update ex
set ex.SystemPath = case ptype.summary
	when 1 then 1
	when 10 then 2
	when 11 then 3
	when 100 then 4
	when 101 then 5
	when 110 then 6
	when 111 then 7
	when 1000 then 8
	when 1001 then 9
	when 1101 then 10
	when 1100 then 11
	else 12 end 
from tmp_Exit ex
inner join ( --CHANGE 10/15/2018 correction to include multiple project types in path 
			 -- where appropriate.
		select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null or nbn.HoHID is not null then 1 else 0 end
				+ case when pshpre.HoHID is not null then 1000 else 0 end
					as summary
		from tmp_Exit ex 
		left outer join sys_Enrollment rrh on rrh.ProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.HHType = ex.HHType
			and rrh.EntryDate <= ex.ExitDate and rrh.ExitDate > ex.LastInactive
		left outer join sys_Enrollment th on th.ProjectType = 2
			and th.HoHID = ex.HoHID and th.HHType = ex.HHType
			and th.EntryDate <= ex.ExitDate and th.ExitDate > ex.LastInactive
		left outer join sys_Enrollment es on es.ProjectType in (1,8)
			and es.HoHID = ex.HoHID and es.HHType = ex.HHType
			and es.EntryDate <= ex.ExitDate and es.ExitDate > ex.LastInactive
		left outer join sys_Enrollment nbn on nbn.EntryDate is null
			and nbn.HoHID = ex.HoHID and nbn.HHType = ex.HHType
		left outer join sys_Enrollment pshpre on pshpre.ProjectType = 3
			and pshpre.HoHID = ex.HoHID and pshpre.HHType = ex.HHType
			and pshpre.EntryDate <= ex.ExitDate
				and coalesce(pshpre.MoveInDate, pshpre.ExitDate) > ex.LastInactive 
		) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType 
		and ptype.Cohort = ex.Cohort
where ex.SystemPath is null

/*****************************************************************
4.47-49 LSACalculated Population Identifiers 

 In the specs, these sections summarize how to select people and 
 households in various populations.    
 
 As demonstrated here, queries used to populate LSACalculated in sections 4.50-4.xx  
 join to a table called ref_Populations to enable use of a single query for each 
 required average and count vs. separate queries for each population.  

4.50 and 4.51 Get Average Days for LOTH 

*****************************************************************/
delete from lsa_Calculated

--AVERAGE DAYS IN ES/SH 
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select distinct avg(ESDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 1 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.ESDays > 0
	and pop.LOTH = 1
	and (lh.SystemPath in (1,3,5,7,9,10,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID
	
-- AVERAGE DAYS IN TH
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select distinct avg(lh.THDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 2 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.THDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (2,3,6,7,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS in ES/SH/TH combined
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select distinct avg(lh.ESTDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 3 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.ESTDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (3,7,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS in RRH/PSH Pre-MoveIn
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select distinct avg(lh.RRHPSHPreMoveInDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 4 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.RRHPSHPreMoveInDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS WHILE HOMELESS
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.SystemHomelessDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 5 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.SystemHomelessDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (5,6,7,10,11,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS Not Enrolled in ES/SH/TH/RRH/PSH PROJECTS 
--  and DOCUMENTED HOMELESS BASED ON 3.917
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.Other3917Days) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 6 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.Other3917Days > 0 
	and pop.LOTH = 1
	and (lh.SystemPath <> -1 or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS HOMELESS IN ES/SH/TH/RRH/PSH projects +
-- DAYS DOCUMENTED HOMELESS BASED ON 3.917
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.TotalHomelessDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 7 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.TotalHomelessDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath <> -1 or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS HOUSED IN RRH
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.RRHHousedDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 8 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.RRHHousedDays > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

--AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS and not Housed in PSH
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.SystemDaysNotPSHHoused) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, 9 as ReportRow
	, lh.ReportID
from tmp_Household lh
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.SystemDaysNotPSHHoused > 0 
	and pop.LOTH = 1
	and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
group by pop.PopID
	, pop.HHType
	, pop.SystemPath
	, lh.ReportID

/******************************************************************
4.52 Cumulative Length of Time Housed in PSH
******************************************************************/
--Time Housed in PSH 
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.PSHHousedDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID
	, -1 as SystemPath
	--Row 10 = households that exited, 11 = active on the last day
	, case when PSHStatus in (12,22) then 10 else 11 end as ReportRow
	, lh.ReportID
from tmp_Household lh 
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.PSHMoveIn > 0 and lh.PSHStatus > 0
	and pop.Core = 1
group by pop.PopID
	, pop.HHType
	, case when PSHStatus in (12,22) then 10 else 11 end 
	, lh.ReportID
/******************************************************************
4.53 Length of Time in RRH Projects
******************************************************************/
--Time in RRH not housed
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.RRHPreMoveInDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID
	, -1 as SystemPath
	--Row 14 = all households placed in PH
	, case when lh.RRHMoveIn in (1,2) then 14
		--Row 12 = exited households not placed in PH
		when RRHStatus in (12,22) then 12 
		--Row 13 = active households not placed in PH
		else 13 end as ReportRow
	, lh.ReportID
from tmp_Household lh 
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.RRHStatus > 2 --CHANGED 10/23/2018 from 'where lh.RRHMoveIn > 0'
	and pop.Core = 1
group by pop.PopID
	, pop.HHType
	, case when lh.RRHMoveIn in (1,2) then 14
		when RRHStatus in (12,22) then 12 
		else 13 end 
	, lh.ReportID

--Time housed in RRH
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lh.RRHHousedDays) as Value
	, 1 as Cohort, -1 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID as Population
	, -1 as SystemPath
	--Row 15 = exited households
	, case when RRHStatus in (12,22) then 15 
		--Row 16 = active households 
		else 16 end as ReportRow
	, lh.ReportID
from tmp_Household lh 
inner join ref_Populations pop on
	(lh.HHType = pop.HHType or pop.HHType is null)
	and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lh.HHVet = pop.HHVet or pop.HHVet is null)
	and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
	and (lh.HHChild = pop.HHChild or pop.HHChild is null)
	and (lh.Stat = pop.Stat or pop.Stat is null)
	and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
	and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lh.RRHMoveIn in (1,2)
	and pop.Core = 1
group by pop.PopID
	, pop.HHType
	, case when RRHStatus in (12,22) then 15 
		else 16 end
	, lh.ReportID
/******************************************************************
4.54 Days to Return/Re-engage by Last Project Type
******************************************************************/
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lx.ReturnTime) as Value
	, lx.Cohort, 
	case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID as Population
	, -1 as SystemPath
	, lx.ExitFrom + 16 as ReportRow
	, lx.ReportID
from tmp_Exit lx
inner join ref_Populations pop on
	(lx.HHType = pop.HHType or pop.HHType is null)
	and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lx.HHVet = pop.HHVet or pop.HHVet is null)
	and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lx.HHParent = pop.HHParent or pop.HHParent is null)
	and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
	and (lx.Stat = pop.Stat or pop.Stat is null)
	and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
where lx.ReturnTime > 0 
	and pop.Core = 1
group by pop.PopID, lx.ReportID
	, lx.Cohort
	, lx.ExitFrom
	, case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end
	, pop.HHType
/******************************************************************
4.55 and 4.56 Days to Return/Re-engage by Population / SystemPath

******************************************************************/
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lx.ReturnTime) as Value
	, lx.Cohort, 
	case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID as Population
	, coalesce(pop.SystemPath, -1)
	, coalesce(pop.SystemPath, 0) + 23 as ReportRow
	, lx.ReportID
from tmp_Exit lx
inner join ref_Populations pop on
	(lx.HHType = pop.HHType or pop.HHType is null)
	and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lx.HHVet = pop.HHVet or pop.HHVet is null)
	and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lx.HHParent = pop.HHParent or pop.HHParent is null)
	and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
	and (lx.Stat = pop.Stat or pop.Stat is null)
	and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	and (lx.SystemPath = pop.SystemPath or pop.SystemPath is null)
where lx.ReturnTime > 0 
	and pop.ReturnSummary = 1
group by pop.PopID, lx.ReportID
	, lx.Cohort
	, case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end
	, pop.HHType
	, pop.SystemPath

/******************************************************************
4.56 Average Days to Return/Re-engage for All NOT Housed in PSH on CohortStart 

******************************************************************/
--Days to return after any path (total row for by-path avgs-- 
--excludes those housed in PSH on cohort start date)
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lx.ReturnTime) as Value
	, lx.Cohort, 
	case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID as Population
	, -1 as SystemPath
	, 36 as ReportRow
	, lx.ReportID
from tmp_Exit lx
inner join ref_Populations pop on
	(lx.HHType = pop.HHType or pop.HHType is null)
	and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lx.HHVet = pop.HHVet or pop.HHVet is null)
	and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lx.HHParent = pop.HHParent or pop.HHParent is null)
	and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
	and (lx.Stat = pop.Stat or pop.Stat is null)
	and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
where lx.ReturnTime > 0 
	and pop.Core = 1
	and lx.SystemPath between 1 and 12
group by pop.PopID, lx.ReportID
	, lx.Cohort
	, case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end
	, pop.HHType

/******************************************************************
4.57 Days to Return/Re-engage by Exit Destination
******************************************************************/
insert into lsa_Calculated (Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select avg(lx.ReturnTime) as Value
	, lx.Cohort, 
	case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID as Population
	, -1 as SystemPath
	, case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end as ReportRow
	, lx.ReportID
from tmp_Exit lx
inner join ref_Populations pop on
	(lx.HHType = pop.HHType or pop.HHType is null)
	and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (lx.HHVet = pop.HHVet or pop.HHVet is null)
	and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (lx.HHParent = pop.HHParent or pop.HHParent is null)
	and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
	and (lx.Stat = pop.Stat or pop.Stat is null)
	and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
	and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
where lx.ReturnTime > 0 
	and pop.Core = 1
group by pop.PopID, lx.ReportID
	, lx.Cohort
	, case when lx.ExitTo between 1 and 6 then 2
		when lx.ExitTo between 7 and 14 then 3 else 4 end
	, pop.HHType
	, case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end

/******************************************************************
4.58 Get Dates for Counts by Project ID and Project Type 
******************************************************************/
delete from tmp_CohortDates where cohort > 0

insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
select 1, rpt.ReportStart, rpt.ReportEnd
from lsa_Report rpt

insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
select distinct case cal.mm 
	when 10 then 10
	when 1 then 11 
	when 4 then 12 
	else 13 end
	, cal.theDate
	, cal.theDate
from lsa_Report rpt 
inner join ref_Calendar cal 
	on cal.theDate between rpt.ReportStart and rpt.ReportEnd
where (cal.mm = 10 and cal.dd = 31 and cal.yyyy = year(rpt.ReportStart))
	or (cal.mm = 1 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))
	or (cal.mm = 4 and cal.dd = 30 and cal.yyyy = year(rpt.ReportEnd))
	or (cal.mm = 7 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))

/******************************************************************
4.59 Get Counts of People by Project ID and Household Characteristics
******************************************************************/
--Count people in households by ProjectID for:
--AO/AC/CO/All All: Disabled Adult/HoH, CH Adult/HoH, Adult/HoH Fleeing DV,
--  and:  AO Youth, AO/AC Vet, AC Youth Parent, CO Parent,
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ProjectID, ReportID)
select count (distinct an.PersonalID)
	, cd.Cohort, 10 as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID as PopID, -1, 53
	, p.ProjectID, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID in (0,1,2,3,5,6,7,9,10) and pop.PopType = 1 
	and pop.SystemPath is null
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID, pop.HHType

/**********************************************************************
4.60 Get Counts of People by Project Type and Household Characteristics
**********************************************************************/
--Unduplicated count of people in households for each project type
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID)
	, cd.Cohort, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end
	, coalesce(pop.HHType, 0) 
	, pop.PopID, -1, 53
	, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID between 0 and 10 and pop.PopType = 1
	and pop.SystemPath is null
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID 
		, p.ProjectType 
		, p.ExportID
		, pop.HHType

--Unduplicated count of people in households for ES/SH/TH combined
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID)
	, cd.Cohort, 16 as Universe
	, coalesce(pop.HHType, 0) 
	, pop.PopID, -1, 53
	, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID between 0 and 10 and pop.PopType = 1
	and pop.SystemPath is null
	and ((p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID 
		, p.ExportID
		, pop.HHType

/******************************************************************
4.61 Get Counts of Households by Project ID 
******************************************************************/
--Count households
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ProjectID, ReportID)
select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
	, cd.Cohort, 10 
	, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 54
	, p.ProjectID, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID in (0,1,2,3,5,6,7,9,10) and pop.PopType = 1
	and pop.SystemPath is null
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID
	, pop.HHType


/******************************************************************
4.62 Get Counts of Households by Project Type 
******************************************************************/
--Unduplicated count households for each project type
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
	, cd.Cohort, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID, -1, 54
	, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID between 0 and 10 and pop.PopType = 1 
	and pop.SystemPath is null
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end, p.ExportID
	, pop.HHType 

--Unduplicated count of households for ES/SH/TH combined
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
	, cd.Cohort, 16 as Universe
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID, -1, 54
	, cast(p.ExportID as int)
from active_Enrollment an 
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
	and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and pop.PopID between 0 and 10 and pop.PopType = 1 and pop.SystemPath is null
	and pop.SystemPath is null
	and (--for night-by-night ES, count only people with bednights in period
		(p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ExportID
	, pop.HHType 

/******************************************************************
4.63 Get Counts of People by ProjectID and Personal Characteristics
******************************************************************/
--Count people with specific characteristic
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ProjectID, ReportID)
select count (distinct lp.PersonalID)
	, cd.Cohort, 10 
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID, -1, 55
	, p.ProjectID, cast(p.ExportID as int)
from tmp_Person lp
inner join active_Enrollment an on an.PersonalID = lp.PersonalID
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	and (an.AgeGroup = pop.Age or pop.Age is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	and (pop.PopID in (3,6) or pop.popID between 145 and 148)
	and pop.PopType = 3
	and pop.ProjectLevelCount = 1
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID
	, pop.HHType


/******************************************************************
4.64 Get Counts of People by Project Type and Personal Characteristics
******************************************************************/
--Count people with specific characteristics for each project type
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct lp.PersonalID)
	, cd.Cohort, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end 
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID, -1, 55
	, cast(p.ExportID as int)
from tmp_Person lp
inner join active_Enrollment an on an.PersonalID = lp.PersonalID
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	and (an.AgeGroup = pop.Age or pop.Age is null)
	and (lp.Gender = pop.Gender or pop.Gender is null)
	and (lp.Race = pop.Race or pop.Race is null)
	and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	--CHANGE 10/23/2018 exclude popID 100, which is not required by specs
	and pop.PopType = 3 and pop.PopID <> 100
	and (
		 --for RRH and PSH, count only people who are housed in period
		(p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd) 
		--for night-by-night ES, count only people with bednights in period
		or (p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ProjectType, p.ExportID
	, pop.HHType

--Count people with specific characteristics for ES/SH/TH combined
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct lp.PersonalID)
	, cd.Cohort, 16 
	, coalesce(pop.HHType, 0) as HHType
	, pop.PopID, -1, 55
	, cast(p.ExportID as int)
from tmp_Person lp
inner join active_Enrollment an on an.PersonalID = lp.PersonalID
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
	and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	and (an.AgeGroup = pop.Age or pop.Age is null)
	and (lp.Gender = pop.Gender or pop.Gender is null)
	and (lp.Race = pop.Race or pop.Race is null)
	and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
	  --The date criteria for these counts differs from the general LSA 
	  --criteria for 'active', which includes those who exited on the start date.
	  --Here, at least one bednight in the cohort period is required, so any exit 
	  --must be at least one day AFTER the start of the cohort period.
	  and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
inner join lsa_Project p on p.ProjectID = an.ProjectID
where cd.Cohort > 0 
	--CHANGE 10/23/2018 exclude PopID 100, which is not required by specs ( issue #8).
	and pop.PopType = 3 and pop.PopID <> 100
	and (
		--for night-by-night ES, count only people with bednights in period
		(p.TrackingMethod = 3 
			and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
		or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
		)
group by cd.Cohort, pop.PopID, p.ExportID
	, pop.HHType

/**********************************************************************
4.65 Get Counts of Bed Nights in Report Period by Project ID
**********************************************************************/
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ProjectID, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, 10, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 56
	, p.ProjectID
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
	and rrhpsh.theDate >= rpt.ReportStart
	and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType

/**********************************************************************
4.66 Get Counts of Bed Nights in Report Period by Project Type
**********************************************************************/
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end 
	, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 56
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
	and rrhpsh.theDate >= rpt.ReportStart
	and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType, p.ProjectType

insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, 16
	, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 56
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
	and p.ProjectType in (1,8,2)
group by p.ExportID, pop.PopID, pop.HHType

/**********************************************************************
4.67 Get Counts of Bed Nights in Report Period by Project ID/Personal Char
**********************************************************************/
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ProjectID, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, 10, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 57
	, p.ProjectID
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join tmp_Person lp on lp.PersonalID = an.PersonalID
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
	and rrhpsh.theDate >= rpt.ReportStart
	and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (3,6) and pop.PopType = 3
group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType

/**********************************************************************
4.68 Get Counts of Bed Nights in Report Period by Project Type/Personal Char
**********************************************************************/
--each project type
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, case p.ProjectType 
		when 1 then 11 
		when 8 then 12	
		when 2 then 13	
		when 13 then 14	
		else 15 end 
	, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 56
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join tmp_Person lp on lp.PersonalID = an.PersonalID
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
	and rrhpsh.theDate >= rpt.ReportStart
	and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (3,6) and pop.PopType = 3
group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType, p.ProjectType

--ES/SH/TH unduplicated
insert into lsa_Calculated
	(Value, Cohort, Universe, HHType
	, Population, SystemPath, ReportRow, ReportID)
select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
	+ count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
	, 1, 16
	, coalesce(pop.HHType, 0)
	, pop.PopID, -1, 56
	, cast(p.ExportID as int)
from active_Enrollment an 
inner join tmp_Person lp on lp.PersonalID = an.PersonalID
inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
inner join ref_Populations pop on
	(ahh.HHType = pop.HHType or pop.HHType is null)
	and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
		 or pop.CHTime is null)
	and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
	and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
	and bn.RecordType = 200
inner join lsa_Project p on p.ProjectID = an.ProjectID
inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
left outer join ref_Calendar est on est.theDate >= an.EntryDate
	and est.theDate >= rpt.ReportStart
	and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
	and p.ProjectType in (1,2,8) and 
		(p.TrackingMethod <> 3 or p.TrackingMethod is null)
left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
	and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
where pop.PopID in (3,6) and pop.PopType = 3
	and p.ProjectType in (1,8,2)
group by p.ExportID, pop.PopID, pop.HHType

/**********************************************************************
4.69 Set LSAReport Data Quality Values for Report Period
**********************************************************************/
update rpt 
	set	UnduplicatedClient1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			where lp.ReportID = rpt.ReportID)
	,	UnduplicatedAdult1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			where lp.ReportID = rpt.ReportID
				and lp.Age between 18 and 65)
	,	AdultHoHEntry1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65))
	,	ClientEntry1 = (select count(distinct n.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment n on n.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID)
	,	ClientExit1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				and an.ExitDate is not null)
	,	Household1 = (select count(distinct an.HouseholdID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID)
	,	HoHPermToPH1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
			inner join hmis_Exit x on x.EnrollmentID = an.EnrollmentID 
			where lp.ReportID = rpt.ReportID
				and an.RelationshipToHoH = 1
				and an.ProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23) )
	,	DOB1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			where lp.ReportID = rpt.ReportID
				and an.AgeGroup in (98,99))
	,	Gender1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				and (c.Gender not in (0,1,2,3,4) or c.Gender is null))
	,	Race1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				and (coalesce(c.AmIndAKNative,0) + coalesce(c.Asian,0) 
					+ coalesce(c.BlackAfAmerican,0) + coalesce(c.NativeHIOtherPacific,0) 
					+ coalesce(c.White,0) = 0
					or c.RaceNone in (8,9,99)))
	,	Ethnicity1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				and (c.Ethnicity not in (0,1) or c.Ethnicity is null))
	,	VetStatus1 = (select count(distinct lp.PersonalID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
				and an.AgeGroup between 18 and 65
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
	,	RelationshipToHoH1 = (select count(distinct n.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment n on n.PersonalID = lp.PersonalID
			where lp.ReportID = rpt.ReportID
				--CHANGE 9/28/2018 add parentheses 
				and (n.RelationshipToHoH not in (1,2,3,4,5) 
					or n.RelationshipToHoH is null))
	,	DisablingCond1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
	,	LivingSituation1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment an on an.PersonalID = lp.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
	,	LengthOfStay1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and an.RelationshipToHoH = 1 
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				-- CHANGE 10/23/2018 add 99 to list of checked values for LengthOfStay
				and (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null))
	,	HomelessDate1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				and ( 
					(hn.LivingSituation in (1,16,18,27) and hn.DateToStreetESSH is null) 
					or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11) 
							and hn.DateToStreetESSH is null)
					or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
						and hn.LivingSituation in (4,5,6,7,15,24) 
						and hn.DateToStreetESSH is null))
					)
	,	TimesHomeless1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				and (hn.TimesHomelessPastThreeYears not between 1 and 4  
					or hn.TimesHomelessPastThreeYears is null))
	,	MonthsHomeless1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				and (hn.MonthsHomelessPastThreeYears not between 101 and 113 
				or hn.MonthsHomelessPastThreeYears is null))
	,	DV1 = (select count(distinct an.EnrollmentID)
			from tmp_Person lp
			inner join hmis_Client c on c.PersonalID = lp.PersonalID
			inner join active_Enrollment an on an.PersonalID = c.PersonalID
			left outer join hmis_HealthAndDV dv on dv.EnrollmentID = an.EnrollmentID
				and dv.DataCollectionStage = 1
			where lp.ReportID = rpt.ReportID
				and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
				and (dv.DomesticViolenceVictim not in (0,1)
						or dv.DomesticViolenceVictim is null
						or (dv.DomesticViolenceVictim = 1 and 
							(dv.CurrentlyFleeing not in (0,1) 
								or dv.CurrentlyFleeing is null))))
	,	Destination1 = (select count(distinct n.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment n on n.PersonalID = lp.PersonalID
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
			where lp.ReportID = rpt.ReportID
				and n.ExitDate is not null
				and (x.Destination in (8,9,17,30,99) or x.Destination is null))
	,	NotOneHoH1 = (select count(distinct ah.HouseholdID)
			from active_Household ah
			left outer join (select an.HouseholdID
					, count(distinct hn.PersonalID) as hoh
				from active_Enrollment an 
				inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
					and hn.RelationshipToHoH = 1
				group by an.HouseholdID
				) hoh on hoh.HouseholdID = ah.HouseholdID
			where hoh.hoh <> 1 or hoh.HouseholdID is null)
	,	MoveInDate1 = coalesce((select count(distinct n.EnrollmentID)
			from tmp_Person lp
			inner join active_Enrollment n on n.PersonalID = lp.PersonalID
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
			where lp.ReportID = rpt.ReportID
				and n.RelationshipToHoH = 1
				and n.ProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23) 
				and n.MoveInDate is null), 0)
from lsa_Report rpt

/**********************************************************************
4.70 Get Relevant Enrollments for Three Year Data Quality Checks
**********************************************************************/
delete from dq_Enrollment
insert into dq_Enrollment (EnrollmentID, PersonalID, HouseholdID, RelationshipToHoH
	, ProjectType, EntryDate, MoveInDate, ExitDate, Adult, SSNValid)

select distinct n.EnrollmentID, n.PersonalID, n.HouseholdID, n.RelationshipToHoH
	, p.ProjectType, n.EntryDate, hhinfo.MoveInDate, ExitDate
	, case when c.DOBDataQuality in (8,9) 
		or c.DOB is null 
		or c.DOB = '1/1/1900'
		or c.DOB > n.EntryDate
		or (c.DOB = n.EntryDate and n.RelationshipToHoH = 1)
		or dateadd(yy, 105, c.DOB) <= n.EntryDate 
		or c.DOBDataQuality is null
		or c.DOBDataQuality not in (1,2) then 99
	when dateadd(yy, 18, c.DOB) <= n.EntryDate then 1 
	else 0 end
, case when c.SSNDataQuality in (8,9) then null
		when SUBSTRING(c.SSN,1,3) in ('000','666')
				or LEN(c.SSN) <> 9
				or SUBSTRING(c.SSN,4,2) = '00'
				or SUBSTRING(c.SSN,6,4) ='0000'
				or c.SSN is null
				or c.SSN = ''
				or c.SSN like '%[^0-9]%'
				or left(c.SSN,1) >= '9'
				or c.SSN in ('123456789','111111111','222222222','333333333','444444444'
						,'555555555','777777777','888888888')
			then 0 else 1 end 
from lsa_report	rpt
inner join hmis_Enrollment n on n.EntryDate <= rpt.ReportEnd
inner join hmis_Project p on p.ProjectID = n.ProjectID
inner join hmis_Client c on c.PersonalID = n.PersonalID
left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
	and x.ExitDate >= dateadd(yy, -3, rpt.ReportStart)
inner join (select distinct hh.HouseholdID, min(hh.MoveInDate) as MoveInDate
	from hmis_Enrollment hh
	inner join lsa_Report rpt on hh.EntryDate <= rpt.ReportEnd
	inner join hmis_Project p on p.ProjectID = hh.ProjectID
	inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hh.EnrollmentID
		and coc.CoCCode = rpt.ReportCoC
	where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
	group by hh.HouseholdID
	) hhinfo on hhinfo.HouseholdID = n.HouseholdID

/**********************************************************************
4.71 Set LSAReport Data Quality Values for Three Year Period
**********************************************************************/
update rpt 
	set	UnduplicatedClient3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n)
	,	UnduplicatedAdult3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n 
			where n.Adult = 1)
	,	AdultHoHEntry3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			where n.Adult = 1 or n.RelationshipToHoH = 1)
	,	ClientEntry3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n)
	,	ClientExit3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			where n.ExitDate is not null)
	,	Household3 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n)
	,	HoHPermToPH3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
			where n.RelationshipToHoH = 1
				and n.ProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23))
	,   NoCoC = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			left outer join hmis_EnrollmentCoC coc on 
				coc.EnrollmentID = n.EnrollmentID 
			inner join hmis_Project p on p.ProjectID = n.ProjectID
				and p.ContinuumProject = 1 and p.ProjectType in (1,2,3,8,13)
			inner join hmis_ProjectCoC pcoc on pcoc.CoCCode = rpt.ReportCoC
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.ExitDate >= dateadd(yy, -3, rpt.ReportStart)
			where n.EntryDate <= rpt.ReportEnd 
				and n.RelationshipToHoH = 1 
				and coc.CoCCode is null)
	,	SSNNotProvided = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.SSNValid is null)
	,	SSNMissingOrInvalid = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.SSNValid = 0)
	,	ClientSSNNotUnique = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			inner join hmis_Client oc on oc.SSN = c.SSN 
				and oc.PersonalID <> c.PersonalID
			inner join dq_Enrollment dqn on dqn.PersonalID = oc.PersonalID 
			where n.SSNValid = 1)
	,	DistinctSSNValueNotUnique = (select count(distinct d.SSN)
			from (select distinct c.SSN
				from hmis_Client c 
				inner join dq_Enrollment n on n.PersonalID = c.PersonalID
					and n.SSNValid = 1
				group by c.SSN
				having count(distinct n.PersonalID) > 1) d)
	,	DOB3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.Adult = 99)
	,	Gender3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
				and (c.Gender not in (0,1,2,3,4) or c.Gender is null))
	,	Race3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where (coalesce(c.AmIndAKNative,0) + coalesce(c.Asian,0) 
					+ coalesce(c.BlackAfAmerican,0) + coalesce(c.NativeHIOtherPacific,0) 
					+ coalesce(c.White,0) = 0
					or c.RaceNone in (8,9,99)))
	,	Ethnicity3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where (c.Ethnicity not in (0,1) or c.Ethnicity is null))
	,	VetStatus3 = (select count(distinct c.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where n.Adult = 1 
				and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
	,	RelationshipToHoH3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			where  (n.RelationshipToHoH not in (1,2,3,4,5) or n.RelationshipToHoH is null))
	,	DisablingCond3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
	,	LivingSituation3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
	,	LengthOfStay3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				-- CHANGE 10/23/2018 add 99 to list of checked values for LengthOfStay				 
				and (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null))
	,	HomelessDate3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				and ( 
				(hn.LivingSituation in (1,16,18,27) and hn.DateToStreetESSH is null) 
					or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11) 
							and hn.DateToStreetESSH is null)
					or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
						and hn.LivingSituation in (4,5,6,7,15,24) 
						and hn.DateToStreetESSH is null))
				)
	,	TimesHomeless3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				and (hn.TimesHomelessPastThreeYears not between 1 and 4  
					or hn.TimesHomelessPastThreeYears is null))
	,	MonthsHomeless3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				and (hn.MonthsHomelessPastThreeYears not between 101 and 113 
				or hn.MonthsHomelessPastThreeYears is null))
	,	DV3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			left outer join hmis_HealthAndDV dv on dv.EnrollmentID = n.EnrollmentID
				and dv.DataCollectionStage = 1
			where (n.RelationshipToHoH = 1 or n.Adult = 1)
				and (dv.DomesticViolenceVictim not in (0,1)
						or dv.DomesticViolenceVictim is null
						or (dv.DomesticViolenceVictim = 1 and 
							(dv.CurrentlyFleeing not in (0,1) 
								or dv.CurrentlyFleeing is null))))
	,	Destination3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
			where n.ExitDate is not null
				and (x.Destination in (8,9,17,30,99) or x.Destination is null))
	,	NotOneHoH3 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n
			left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
				from hmis_Enrollment hn
				where hn.RelationshipToHoH = 1
				group by hn.HouseholdID
			) hoh on hoh.HouseholdID = n.HouseholdID
			where hoh.hoh <> 1 or hoh.HouseholdID is null)
	,	MoveInDate3 = coalesce((select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
			where n.RelationshipToHoH = 1
				and n.ProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23) 
				and n.MoveInDate is null), 0)
from lsa_Report rpt

/**********************************************************************
4.72 Set ReportDate for LSAReport
**********************************************************************/
update lsa_Report set ReportDate = getdate()

/**********************************************************************
4.73 Select Data for Export
**********************************************************************/
-- LSAPerson
delete from lsa_Person
insert into lsa_Person (RowTotal
	, Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
	, CHTime, CHTimeStatus, DVStatus
	, HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
	, HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID)
select count(distinct PersonalID)
	, Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
	, CHTime, CHTimeStatus, DVStatus
	, HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
	, HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID
from tmp_Person
group by Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
	, CHTime, CHTimeStatus, DVStatus
	, HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
	, HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID

-- LSAHousehold
delete from lsa_Household
insert into lsa_Household(RowTotal
	, Stat, ReturnTime, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
	, HoHRace, HoHEthnicity, HHAdult, HHChild, HHNoDOB, HHAdultAge
	, HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
	, ESDays, THDays, ESTDays
	, ESTGeography, ESTLivingSit, ESTDestination
	, RRHPreMoveInDays, RRHPSHPreMoveInDays, RRHHousedDays, SystemDaysNotPSHHoused
	, RRHGeography, RRHLivingSit, RRHDestination
	, SystemHomelessDays, Other3917Days, TotalHomelessDays 
	, PSHGeography, PSHLivingSit, PSHDestination
	, PSHHousedDays, SystemPath, ReportID)
select count (distinct HoHID + cast(HHType as nvarchar)), Stat
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
	, HoHRace, HoHEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge
	, HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
	, case when ESDays between 1 and 7 then 7
		when ESDays between 8 and 30 then 30 
		when ESDays between 31 and 60 then 60 
		when ESDays between 61 and 90 then 90 
		when ESDays between 91 and 180 then 180 
		when ESDays between 181 and 365 then 365 
		when ESDays between 366 and 547 then 547 
		when ESDays between 548 and 730 then 730 
		when ESDays between 731 and 1094 then 1094 
		when ESDays > 1094 then 1095
		else ESDays end 
	, case when THDays between 1 and 7 then 7
		when THDays between 8 and 30 then 30 
		when THDays between 31 and 60 then 60 
		when THDays between 61 and 90 then 90 
		when THDays between 91 and 180 then 180 
		when THDays between 181 and 365 then 365 
		when THDays between 366 and 547 then 547 
		when THDays between 548 and 730 then 730 
		when THDays between 731 and 1094 then 1094 
		when THDays > 1094 then 1095
		else THDays end 
	, case when ESTDays between 1 and 7 then 7
		when ESTDays between 8 and 30 then 30 
		when ESTDays between 31 and 60 then 60 
		when ESTDays between 61 and 90 then 90 
		when ESTDays between 91 and 180 then 180 
		when ESTDays between 181 and 365 then 365 
		when ESTDays between 366 and 547 then 547 
		when ESTDays between 548 and 730 then 730 
		when ESTDays between 731 and 1094 then 1094 
		when ESTDays > 1094 then 1095
		else ESTDays end 
	, ESTGeography, ESTLivingSit, ESTDestination
	, case when RRHPreMoveInDays between 1 and 7 then 7
		when RRHPreMoveInDays between 8 and 30 then 30 
		when RRHPreMoveInDays between 31 and 60 then 60 
		when RRHPreMoveInDays between 61 and 90 then 90 
		when RRHPreMoveInDays between 91 and 180 then 180 
		when RRHPreMoveInDays between 181 and 365 then 365 
		when RRHPreMoveInDays between 366 and 547 then 547 
		when RRHPreMoveInDays between 548 and 730 then 730 
		when RRHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPreMoveInDays > 1094 then 1095
		else RRHPreMoveInDays end 
	, case when RRHPSHPreMoveInDays between 1 and 7 then 7
		when RRHPSHPreMoveInDays between 8 and 30 then 30 
		when RRHPSHPreMoveInDays between 31 and 60 then 60 
		when RRHPSHPreMoveInDays between 61 and 90 then 90 
		when RRHPSHPreMoveInDays between 91 and 180 then 180 
		when RRHPSHPreMoveInDays between 181 and 365 then 365 
		when RRHPSHPreMoveInDays between 366 and 547 then 547 
		when RRHPSHPreMoveInDays between 548 and 730 then 730 
		when RRHPSHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPSHPreMoveInDays > 1094 then 1095
		else RRHPSHPreMoveInDays end 
	, case when RRHHousedDays between 1 and 7 then 7
		when RRHHousedDays between 8 and 30 then 30 
		when RRHHousedDays between 31 and 60 then 60 
		when RRHHousedDays between 61 and 90 then 90 
		when RRHHousedDays between 91 and 180 then 180 
		when RRHHousedDays between 181 and 365 then 365 
		when RRHHousedDays between 366 and 547 then 547 
		when RRHHousedDays between 548 and 730 then 730 
		when RRHHousedDays between 731 and 1094 then 1094 
		when RRHHousedDays > 1094 then 1095
		else RRHHousedDays end 
	, case when SystemDaysNotPSHHoused between 1 and 7 then 7
		when SystemDaysNotPSHHoused between 8 and 30 then 30 
		when SystemDaysNotPSHHoused between 31 and 60 then 60 
		when SystemDaysNotPSHHoused between 61 and 90 then 90 
		when SystemDaysNotPSHHoused between 91 and 180 then 180 
		when SystemDaysNotPSHHoused between 181 and 365 then 365 
		when SystemDaysNotPSHHoused between 366 and 547 then 547 
		when SystemDaysNotPSHHoused between 548 and 730 then 730 
		when SystemDaysNotPSHHoused between 731 and 1094 then 1094 
		when SystemDaysNotPSHHoused > 1094 then 1095
		else SystemDaysNotPSHHoused end 
	, RRHGeography, RRHLivingSit, RRHDestination
	, case when SystemHomelessDays between 1 and 7 then 7
		when SystemHomelessDays between 8 and 30 then 30 
		when SystemHomelessDays between 31 and 60 then 60 
		when SystemHomelessDays between 61 and 90 then 90 
		when SystemHomelessDays between 91 and 180 then 180 
		when SystemHomelessDays between 181 and 365 then 365 
		when SystemHomelessDays between 366 and 547 then 547 
		when SystemHomelessDays between 548 and 730 then 730 
		when SystemHomelessDays between 731 and 1094 then 1094 
		when SystemHomelessDays > 1094 then 1095
		else SystemHomelessDays end 
	, case when Other3917Days between 1 and 7 then 7
		when Other3917Days between 8 and 30 then 30 
		when Other3917Days between 31 and 60 then 60 
		when Other3917Days between 61 and 90 then 90 
		when Other3917Days between 91 and 180 then 180 
		when Other3917Days between 181 and 365 then 365 
		when Other3917Days between 366 and 547 then 547 
		when Other3917Days between 548 and 730 then 730 
		when Other3917Days between 731 and 1094 then 1094 
		when Other3917Days > 1094 then 1095
		else Other3917Days end 
	, case when TotalHomelessDays between 1 and 7 then 7
		when TotalHomelessDays between 8 and 30 then 30 
		when TotalHomelessDays between 31 and 60 then 60 
		when TotalHomelessDays between 61 and 90 then 90 
		when TotalHomelessDays between 91 and 180 then 180 
		when TotalHomelessDays between 181 and 365 then 365 
		when TotalHomelessDays between 366 and 547 then 547 
		when TotalHomelessDays between 548 and 730 then 730 
		when TotalHomelessDays between 731 and 1094 then 1094 
		when TotalHomelessDays > 1094 then 1095
		else TotalHomelessDays end 
	, PSHGeography, PSHLivingSit, PSHDestination
	--NOTE:  These are different grouping categories from above!
	, case when PSHMoveIn not in (1,2) then -1
		when PSHHousedDays <= 90 then 3
		when PSHHousedDays between 91 and 180 then 6 
		when PSHHousedDays between 181 and 365 then 12 
		when PSHHousedDays between 366 and 730 then 24 
		when PSHHousedDays between 731 and 1095 then 36 
		when PSHHousedDays between 1096 and 1460 then 48 
		when PSHHousedDays between 1461 and 1825 then 60 
		when PSHHousedDays between 1826 and 2555 then 84 
		when PSHHousedDays between 2556 and 3650 then 120 
		when PSHHousedDays > 3650 then 121
		else PSHHousedDays end 
	, SystemPath, ReportID
from tmp_Household
group by Stat	
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
	, HoHRace, HoHEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge
	, HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
	, case when ESDays between 1 and 7 then 7
		when ESDays between 8 and 30 then 30 
		when ESDays between 31 and 60 then 60 
		when ESDays between 61 and 90 then 90 
		when ESDays between 91 and 180 then 180 
		when ESDays between 181 and 365 then 365 
		when ESDays between 366 and 547 then 547 
		when ESDays between 548 and 730 then 730 
		when ESDays between 731 and 1094 then 1094 
		when ESDays > 1094 then 1095
		else ESDays end 
	, case when THDays between 1 and 7 then 7
		when THDays between 8 and 30 then 30 
		when THDays between 31 and 60 then 60 
		when THDays between 61 and 90 then 90 
		when THDays between 91 and 180 then 180 
		when THDays between 181 and 365 then 365 
		when THDays between 366 and 547 then 547 
		when THDays between 548 and 730 then 730 
		when THDays between 731 and 1094 then 1094 
		when THDays > 1094 then 1095
		else THDays end 
	, case when ESTDays between 1 and 7 then 7
		when ESTDays between 8 and 30 then 30 
		when ESTDays between 31 and 60 then 60 
		when ESTDays between 61 and 90 then 90 
		when ESTDays between 91 and 180 then 180 
		when ESTDays between 181 and 365 then 365 
		when ESTDays between 366 and 547 then 547 
		when ESTDays between 548 and 730 then 730 
		when ESTDays between 731 and 1094 then 1094 
		when ESTDays > 1094 then 1095
		else ESTDays end 
	, ESTGeography, ESTLivingSit, ESTDestination
	, case when RRHPreMoveInDays between 1 and 7 then 7
		when RRHPreMoveInDays between 8 and 30 then 30 
		when RRHPreMoveInDays between 31 and 60 then 60 
		when RRHPreMoveInDays between 61 and 90 then 90 
		when RRHPreMoveInDays between 91 and 180 then 180 
		when RRHPreMoveInDays between 181 and 365 then 365 
		when RRHPreMoveInDays between 366 and 547 then 547 
		when RRHPreMoveInDays between 548 and 730 then 730 
		when RRHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPreMoveInDays > 1094 then 1095
		else RRHPreMoveInDays end 
	, case when RRHPSHPreMoveInDays between 1 and 7 then 7
		when RRHPSHPreMoveInDays between 8 and 30 then 30 
		when RRHPSHPreMoveInDays between 31 and 60 then 60 
		when RRHPSHPreMoveInDays between 61 and 90 then 90 
		when RRHPSHPreMoveInDays between 91 and 180 then 180 
		when RRHPSHPreMoveInDays between 181 and 365 then 365 
		when RRHPSHPreMoveInDays between 366 and 547 then 547 
		when RRHPSHPreMoveInDays between 548 and 730 then 730 
		when RRHPSHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPSHPreMoveInDays > 1094 then 1095
		else RRHPSHPreMoveInDays end 
	, case when RRHHousedDays between 1 and 7 then 7
		when RRHHousedDays between 8 and 30 then 30 
		when RRHHousedDays between 31 and 60 then 60 
		when RRHHousedDays between 61 and 90 then 90 
		when RRHHousedDays between 91 and 180 then 180 
		when RRHHousedDays between 181 and 365 then 365 
		when RRHHousedDays between 366 and 547 then 547 
		when RRHHousedDays between 548 and 730 then 730 
		when RRHHousedDays between 731 and 1094 then 1094 
		when RRHHousedDays > 1094 then 1095
		else RRHHousedDays end 
	, case when SystemDaysNotPSHHoused between 1 and 7 then 7
		when SystemDaysNotPSHHoused between 8 and 30 then 30 
		when SystemDaysNotPSHHoused between 31 and 60 then 60 
		when SystemDaysNotPSHHoused between 61 and 90 then 90 
		when SystemDaysNotPSHHoused between 91 and 180 then 180 
		when SystemDaysNotPSHHoused between 181 and 365 then 365 
		when SystemDaysNotPSHHoused between 366 and 547 then 547 
		when SystemDaysNotPSHHoused between 548 and 730 then 730 
		when SystemDaysNotPSHHoused between 731 and 1094 then 1094 
		when SystemDaysNotPSHHoused > 1094 then 1095
		else SystemDaysNotPSHHoused end 
	, RRHGeography, RRHLivingSit, RRHDestination
	, case when SystemHomelessDays between 1 and 7 then 7
		when SystemHomelessDays between 8 and 30 then 30 
		when SystemHomelessDays between 31 and 60 then 60 
		when SystemHomelessDays between 61 and 90 then 90 
		when SystemHomelessDays between 91 and 180 then 180 
		when SystemHomelessDays between 181 and 365 then 365 
		when SystemHomelessDays between 366 and 547 then 547 
		when SystemHomelessDays between 548 and 730 then 730 
		when SystemHomelessDays between 731 and 1094 then 1094 
		when SystemHomelessDays > 1094 then 1095
		else SystemHomelessDays end 
	, case when Other3917Days between 1 and 7 then 7
		when Other3917Days between 8 and 30 then 30 
		when Other3917Days between 31 and 60 then 60 
		when Other3917Days between 61 and 90 then 90 
		when Other3917Days between 91 and 180 then 180 
		when Other3917Days between 181 and 365 then 365 
		when Other3917Days between 366 and 547 then 547 
		when Other3917Days between 548 and 730 then 730 
		when Other3917Days between 731 and 1094 then 1094 
		when Other3917Days > 1094 then 1095
		else Other3917Days end 
	, case when TotalHomelessDays between 1 and 7 then 7
		when TotalHomelessDays between 8 and 30 then 30 
		when TotalHomelessDays between 31 and 60 then 60 
		when TotalHomelessDays between 61 and 90 then 90 
		when TotalHomelessDays between 91 and 180 then 180 
		when TotalHomelessDays between 181 and 365 then 365 
		when TotalHomelessDays between 366 and 547 then 547 
		when TotalHomelessDays between 548 and 730 then 730 
		when TotalHomelessDays between 731 and 1094 then 1094 
		when TotalHomelessDays > 1094 then 1095
		else TotalHomelessDays end 
	, PSHGeography, PSHLivingSit, PSHDestination
	, case when PSHMoveIn not in (1,2) then -1
		--CHANGE 10/23/2018 set to 3 for <= 90, not < 90
		when PSHHousedDays <= 90 then 3
		when PSHHousedDays between 91 and 180 then 6 
		when PSHHousedDays between 181 and 365 then 12 
		when PSHHousedDays between 366 and 730 then 24 
		when PSHHousedDays between 731 and 1095 then 36 
		when PSHHousedDays between 1096 and 1460 then 48 
		when PSHHousedDays between 1461 and 1825 then 60 
		when PSHHousedDays between 1826 and 2555 then 84 
		when PSHHousedDays between 2556 and 3650 then 120 
		when PSHHousedDays > 3650 then 121
		else PSHHousedDays end 
	, SystemPath, ReportID
	
-- LSAExit
delete from lsa_Exit
insert into lsa_Exit (RowTotal
	, Cohort, Stat, ExitFrom, ExitTo, ReturnTime, HHType
	, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID)
select count (distinct HoHID + cast(HHType as nvarchar))
	, Cohort, Stat, ExitFrom, ExitTo
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID
from tmp_Exit
group by Cohort, Stat, ExitFrom, ExitTo
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID

/**********************************************************************
END
**********************************************************************/
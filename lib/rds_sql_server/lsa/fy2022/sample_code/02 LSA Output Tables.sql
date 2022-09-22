/*
LSA FY2022 Sample Code
Name:  02 LSA Output Tables.sql 

FY2022 Changes
		lsa_Report
			- Revise DQ columns (all 3 year DQ counts have been removed)
			- Add LookbackDate

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)


	There are some deliberate differences from data typing and nullability as defined by 
	the HMIS CSV/LSA specs and the CREATE statements here. 

	Columns which may be NULL in the HMIS CSV under some circumstances that do not
	apply to the LSA upload are created as NOT NULL here.  For example, ProjectType 
	may be NULL in HMIS if ContinuumProject = 0, but may not be NULL in the LSA
	because all projects included in the upload must have ContinuumProject = 1.
	
	Columns which may not be NULL in HMIS but are not relevant to the LSA are
	created as NULL here.  For example, UserID values are not imported to the HDX 
	and may be NULL in the LSA upload. 
	
	Date columns are created with data type nvarchar to enable date formatting as 
	required by HMIS/LSA CSV specs in the INSERT statements.  The only exception is
	DateDeleted columns -- they must be NULL for all records and formatting is not
	relevant.

	ExportID columns have a string(32) data type for HMIS purposes, but the values 
	must match the LSA ReportID, which is an int column; they are created here as int
	to ensure that the data type, at least, is consistent with LSA requirements.


	2.1 Project.csv / lsa_Project
*/
if object_id ('lsa_Project') is not NULL drop table lsa_Project

--	ProjectType and HousingType may be NULL under some circumstances in the HMIS CSV;
--	none of those circumstances apply to projects included in the LSA upload.

create table lsa_Project(
	ProjectID nvarchar(32) not NULL,
	OrganizationID nvarchar(32) not NULL,
	ProjectName nvarchar(100) not NULL,
	ProjectCommonName nvarchar(50),
	OperatingStartDate nvarchar(10) not NULL,	--HMIS: date
	OperatingEndDate nvarchar(10),				--HMIS: date
	ContinuumProject int not NULL,
	ProjectType int not NULL,					--HMIS: may be NULL
	HousingType int not NULL,					--HMIS: may be NULL
	ResidentialAffiliation int,
	TrackingMethod int,
	HMISParticipatingProject int not NULL,
	TargetPopulation int,
	HOPWAMedAssistedLivingFac int,
	PITCount int,
	DateCreated nvarchar(19) not NULL,			--HMIS: datetime
	DateUpdated nvarchar(19) not NULL,			--HMIS: datetime
	UserID nvarchar(32),						--HMIS: not NULL
	DateDeleted datetime,
	ExportID int not NULL,						--HMIS: string(32)
	CONSTRAINT pk_lsa_Project PRIMARY KEY CLUSTERED (ProjectID) 
	)

/*
	2.2 Organization.csv / lsa_Organization
*/
if object_id ('lsa_Organization') is not NULL drop table lsa_Organization

create table lsa_Organization(
	OrganizationID nvarchar(32) not NULL,
	OrganizationName nvarchar(50) not NULL,
	VictimServiceProvider int not NULL,
	OrganizationCommonName nvarchar(50),
	DateCreated nvarchar(19) not NULL,			--HMIS: datetime
	DateUpdated nvarchar(19) not NULL,			--HMIS: datetime
	UserID nvarchar(32),						--HMIS: not NULL
	DateDeleted datetime,
	ExportID int not NULL,						--HMIS: string(32)
	CONSTRAINT pk_lsa_Organization PRIMARY KEY CLUSTERED (OrganizationID)
	)

/*
	2.3 Funder.csv / lsa_Funder
*/

if object_id ('lsa_Funder') is not NULL drop table lsa_Funder

--	GrantID may not be NULL in HMIS, but it is not relevant for the LSA.

create table lsa_Funder(
	FunderID nvarchar(32) not NULL,
	ProjectID nvarchar(32) not NULL,
	Funder int not NULL,
	OtherFunder nvarchar(50),
	GrantID nvarchar(32),						--HMIS: not NULL
	StartDate nvarchar(10) not NULL,			--HMIS: date
	EndDate nvarchar(10),						--HMIS: date
	DateCreated nvarchar(19) not NULL,			--HMIS: datetime
	DateUpdated nvarchar(19) not NULL,			--HMIS: datetime
	UserID nvarchar(32),						--HMIS: not NULL
	DateDeleted datetime,
	ExportID int not NULL,						--HMIS: string(32)
	CONSTRAINT pk_lsa_Funder PRIMARY KEY CLUSTERED (FunderID)
	)

/*
	2.4 ProjectCoC.csv / lsa_ProjectCoC
*/
if object_id ('lsa_ProjectCoC') is not NULL drop table lsa_ProjectCoC

--	ZIP and GeographyType are mandatory for the LSA.
create table lsa_ProjectCoC(
	ProjectCoCID nvarchar(32) not NULL,
	ProjectID nvarchar(32) not NULL,
	CoCCode nvarchar(6) not NULL,
	Geocode nvarchar(6) not NULL,				
	Address1 nvarchar(100),
	Address2 nvarchar(100),	
	City nvarchar(50),
	[State] nvarchar(2),
	ZIP nvarchar(5),					
	GeographyType int,					
	DateCreated nvarchar(19) not NULL,			--HMIS: datetime
	DateUpdated nvarchar(19) not NULL,			--HMIS: datetime
	UserID nvarchar(32),						--HMIS: not NULL
	DateDeleted datetime,
	ExportID int not NULL,						--HMIS: string(32)
	CONSTRAINT pk_lsa_ProjectCoC PRIMARY KEY CLUSTERED (ProjectCoCID)
	)

/*
	2.5 Inventory.csv / lsa_Inventory
*/
if object_id ('lsa_Inventory') is not NULL drop table lsa_Inventory

--	xInventory (e.g., CHVetBedInventory, etc.) columns for which the HMIS CSV permits
--	  NULL values are mandatory for the LSA and created here as NOT NULL.
--  BedInventory MUST be equal to the sum of values in xInventory columns.  It is set up 
--    here as a computed column, which is permissible. 
create table lsa_Inventory(
	InventoryID nvarchar(32) not NULL,
	ProjectID nvarchar(32) not NULL,
	CoCCode nvarchar(6)  not NULL, 
	HouseholdType int not NULL, 
	[Availability] int, 
	UnitInventory int not NULL, 
	BedInventory 
		as CHVetBedInventory + YouthVetBedInventory + VetBedInventory
		   + CHYouthBedInventory + YouthBedInventory + CHBedInventory
		   + OtherBedInventory,  
	CHVetBedInventory int not NULL,				--HMIS: may be NULL 
	YouthVetBedInventory int not NULL,			--HMIS: may be NULL 
	VetBedInventory int not NULL,				--HMIS: may be NULL 
	CHYouthBedInventory int not NULL,			--HMIS: may be NULL
	YouthBedInventory int not NULL,				--HMIS: may be NULL
	CHBedInventory int not NULL,				--HMIS: may be NULL
	OtherBedInventory int not NULL,				--HMIS: may be NULL
	ESBedType int,  
	InventoryStartDate nvarchar(10) not NULL,	--HMIS: date
	InventoryEndDate nvarchar(10),				--HMIS: date
	DateCreated nvarchar(19) not NULL,			--HMIS: datetime
	DateUpdated nvarchar(19) not NULL,			--HMIS: datetime
	UserID nvarchar(32),						--HMIS: not NULL
	DateDeleted datetime,
	ExportID int not NULL,						--HMIS: string(32)
	CONSTRAINT pk_lsa_Inventory PRIMARY KEY CLUSTERED (InventoryID)
	)

/*
	2.6 LSAReport.csv / lsa_Report
*/
if object_id ('lsa_Report') is not NULL drop table lsa_Report

--	The NULL/NOT NULL requirements for this table as it is created here
--	differ from those for the LSAReport.csv file because the values are not
--	populated in a single step. All columns must be non-NULL in the upload.
create table lsa_Report(
	ReportID int not NULL,
	ReportDate datetime,
	ReportStart date not NULL,
	ReportEnd date not NULL,
	ReportCoC nvarchar(6) not NULL,
	SoftwareVendor nvarchar(50) not NULL,
	SoftwareName nvarchar(50) not NULL,
	VendorContact nvarchar(50) not NULL,
	VendorEmail nvarchar(50) not NULL,
	LSAScope int not NULL,
	LookbackDate date not NULL,
	NoCoC int,
	NotOneHoH int,
	RelationshipToHoH int,
	MoveInDate int,
	UnduplicatedClient int,
	HouseholdEntry int,
	ClientEntry int,
	AdultHoHEntry int,
	ClientExit int,
	SSNNotProvided int,
	SSNMissingOrInvalid int,
	ClientSSNNotUnique int,
	DistinctSSNValueNotUnique int,
	DisablingCond int,
	LivingSituation int,
	LengthOfStay int,
	HomelessDate int,
	TimesHomeless int,
	MonthsHomeless int,
	Destination int
	) 

/*
	2.7 LSAPerson.csv / lsa_Person
*/

if object_id ('lsa_Person') is not NULL drop table lsa_Person

create table lsa_Person (
	RowTotal int not NULL,
	Gender int not NULL,
	Race int not NULL,
	Ethnicity int not NULL,
	VetStatus int not NULL,
	DisabilityStatus int not NULL,
	CHTime int not NULL,
	CHTimeStatus int not NULL,
	DVStatus int not NULL,
	ESTAgeMin int not NULL,
	ESTAgeMax int not NULL,
	HHTypeEST int not NULL,
	HoHEST int not NULL,
	AdultEST int not NULL,
	AHARAdultEST int not NULL,
	HHChronicEST int not NULL,
	HHVetEST int not NULL,
	HHDisabilityEST int not NULL,
	HHFleeingDVEST int not NULL,
	HHAdultAgeAOEST int not NULL,
	HHAdultAgeACEST int not NULL,
	HHParentEST int not NULL,
	AC3PlusEST int not NULL,
	AHAREST int not NULL,
	AHARHoHEST int not NULL,
	RRHAgeMin int not NULL,
	RRHAgeMax int not NULL,
	HHTypeRRH int not NULL,
	HoHRRH int not NULL,
	AdultRRH int not NULL,
	AHARAdultRRH int not NULL,
	HHChronicRRH int not NULL,
	HHVetRRH int not NULL,
	HHDisabilityRRH int not NULL,
	HHFleeingDVRRH int not NULL,
	HHAdultAgeAORRH int not NULL,
	HHAdultAgeACRRH int not NULL,
	HHParentRRH int not NULL,
	AC3PlusRRH int not NULL,
	AHARRRH int not NULL,
	AHARHoHRRH int not NULL,
	PSHAgeMin int not NULL,
	PSHAgeMax int not NULL,
	HHTypePSH int not NULL,
	HoHPSH int not NULL,
	AdultPSH int not NULL,
	AHARAdultPSH int not NULL,
	HHChronicPSH int not NULL,
	HHVetPSH int not NULL,
	HHDisabilityPSH int not NULL,
	HHFleeingDVPSH int not NULL,
	HHAdultAgeAOPSH int not NULL,
	HHAdultAgeACPSH int not NULL,
	HHParentPSH int not NULL,
	AC3PlusPSH int not NULL,
	AHARPSH int not NULL,
	AHARHoHPSH int not NULL,
	ReportID int not NULL
	)

/*
	2.8 LSAHousehold.csv / lsa_Household
*/
if object_id ('lsa_Household') is not NULL drop table lsa_Household

create table lsa_Household(
	RowTotal int not NULL,
	Stat int not NULL,
	ReturnTime int not NULL,
	HHType int not NULL,
	HHChronic int not NULL,
	HHVet int not NULL,
	HHDisability int not NULL,
	HHFleeingDV int not NULL,
	HoHRace int not NULL,
	HoHEthnicity int not NULL,
	HHAdult int not NULL,
	HHChild int not NULL,
	HHNoDOB int not NULL,
	HHAdultAge int not NULL,
	HHParent int not NULL,
	ESTStatus int not NULL,
	ESTGeography int not NULL,
	ESTLivingSit int not NULL,
	ESTDestination int not NULL,
	ESTChronic int not NULL,
	ESTVet int not NULL,
	ESTDisability int not NULL,
	ESTFleeingDV int not NULL,
	ESTAC3Plus int not NULL,
	ESTAdultAge int not NULL,
	ESTParent int not NULL,
	RRHStatus int not NULL,
	RRHMoveIn int not NULL,
	RRHGeography int not NULL,
	RRHLivingSit int not NULL,
	RRHDestination int not NULL,
	RRHPreMoveInDays int not NULL,
	RRHChronic int not NULL,
	RRHVet int not NULL,
	RRHDisability int not NULL,
	RRHFleeingDV int not NULL,
	RRHAC3Plus int not NULL,
	RRHAdultAge int not NULL,
	RRHParent int not NULL,
	PSHStatus int not NULL,
	PSHMoveIn int not NULL,
	PSHGeography int not NULL,
	PSHLivingSit int not NULL,
	PSHDestination int not NULL,
	PSHHousedDays int not NULL,
	PSHChronic int not NULL,
	PSHVet int not NULL,
	PSHDisability int not NULL,
	PSHFleeingDV int not NULL,
	PSHAC3Plus int not NULL,
	PSHAdultAge int not NULL,
	PSHParent int not NULL,
	ESDays int not NULL,
	THDays int not NULL,
	ESTDays int not NULL,
	RRHPSHPreMoveInDays int not NULL,
	RRHHousedDays int not NULL,
	SystemDaysNotPSHHoused int not NULL,
	SystemHomelessDays int not NULL,
	Other3917Days int not NULL,
	TotalHomelessDays int not NULL,
	SystemPath int not NULL,
	ESTAHAR int not NULL,
	RRHAHAR int not NULL,
	PSHAHAR int not NULL,
	ReportID int not NULL
	)

/*
	2.9 LSAExit.csv / lsa_Exit
*/
if object_id ('lsa_Exit') is not NULL drop table lsa_Exit
 
create table lsa_Exit(
	RowTotal int not NULL,
	Cohort int not NULL,
	Stat int not NULL,

	ExitFrom int not NULL,
	ExitTo int not NULL,
	ReturnTime int not NULL,

	HHType int not NULL,
	HHVet int not NULL,
	HHChronic int not NULL,
	HHDisability int not NULL,
	HHFleeingDV int not NULL,
	HoHRace int not NULL,
	HoHEthnicity int not NULL,
	HHAdultAge int not NULL,
	HHParent int not NULL,
	AC3Plus int not NULL,
	SystemPath int not NULL,
	ReportID int not NULL
	)

/*
	2.10 LSACalculated.csv / lsa_Calculated
*/

if object_id ('lsa_Calculated') is not NULL drop table lsa_Calculated 

create table lsa_Calculated(
	Value int not NULL,
	Cohort int not NULL,
	Universe int not NULL,
	HHType int not NULL,
	[Population] int not NULL,
	SystemPath int not NULL,
	ProjectID nvarchar(32),
	ReportRow int not NULL,
	ReportID int not NULL,
	Step nvarchar(10) not NULL
	)


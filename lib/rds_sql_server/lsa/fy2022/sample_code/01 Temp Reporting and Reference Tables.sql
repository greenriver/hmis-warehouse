/*
LSA FY2022 Sample Code
Name:  01 Temp Reporting and Reference Tables.sql

FY2022 Changes
		tlsa_CohortDates - add column LookbackDate (to avoid repeating the dateadd function every time the date is required)

		tlsa_Person 
			- Add column SSNValid (was formerly in dq_Enrollment, which is no longer needed as DQ reporting is limited 
				to the active cohort)

		tlsa_HHID 
			- Delete columns DQ1, DQ3 

		dq_Enrollment
			- Deleted -- DQ now limited to the active cohort

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

This script drops (if tables exist) and creates the following temp reporting tables:

	tlsa_CohortDates - based on ReportStart and ReportEnd, all cohorts and dates used in the LSA
	tlsa_HHID - 'master' table of HMIS HouseholdIDs active in continuum ES/SH/TH/RRH/PSH projects 
			between 10/1/2012 and ReportEnd.  Used to store adjusted move-in and exit dates, 
			household types, and other frequently-referenced data 
	tlsa_Enrollment - a 'master' table of enrollments associated with the HouseholdIDs in tlsa_HHID
			with enrollment ages and other frequently-referenced data

	tlsa_Person - a person-level pre-cursor to LSAPerson / people active in report period
		ch_Exclude - dates in TH or housed in RRH/PSH; used for LSAPerson chronic homelessness determination
		ch_Include - dates in ES/SH or on the street; used for LSAPerson chronic homelessness determination
		ch_Episodes - episodes of ES/SH/Street time constructed from ch_Include for chronic homelessness determination
	tlsa_Household - a household-level precursor to LSAHousehold / households active in report period
		sys_TimePadded - used to identify households' last inactive date for SystemPath 
		sys_Time - used to count dates in ES/SH, TH, RRH/PSH but not housed, housed in RRH/PSH, and ES/SH/StreetDates
	tlsa_Exit - household-level precursor to LSAExit / households with system exits in exit cohort periods
	tlsa_ExitHoHAdult - used as the basis for determining chronic homelessness for LSAExit
	tlsa_AveragePops - used to identify households in various populations for average # of days in section 8 
		based on LSAHousehold and LSAExit.
	tlsa_CountPops - used to identify people/households in various populations for AHAR counts in section 9.

This script drops (if tables exist), creates, and populates the following 
reference tables used in the sample code:  
	ref_Calendar - table of dates between 10/1/2012 and 9/30/2022
	ref_RowValues - required combinations of Cohort, Universe, and SystemPath values for each ReportRow in LSACalculated
	ref_RowPopulations - the populations required for each ReportRow in LSACalculated
	ref_PopHHTypes - the household types associated with each population 
	
*/

if object_id ('tlsa_CohortDates') is not null drop table tlsa_CohortDates
	
create table tlsa_CohortDates (
	Cohort int
	, CohortStart date
	, CohortEnd date
	, LookbackDate date
	, ReportID int
	, constraint pk_tlsa_CohortDates primary key clustered (Cohort)
	)
	;

if object_id ('tlsa_HHID') is not NULL drop table tlsa_HHID 

create table tlsa_HHID (
	 HouseholdID varchar(32)
	, HoHID varchar(32)
	, EnrollmentID varchar(32)
	, ProjectID varchar(32)
	, LSAProjectType int
	, EntryDate date
	, MoveInDate date
	, ExitDate date
	, LastBednight date
	, EntryHHType int
	, ActiveHHType int
	, Exit1HHType int
	, Exit2HHType int
	, ExitDest int
	, Active bit default 0
	, AHAR bit default 0
	, PITOctober bit default 0
	, PITJanuary bit default 0
	, PITApril bit default 0
	, PITJuly bit default 0
	, ExitCohort int
	, HHChronic int default 0
	, HHVet int default 0
	, HHDisability int default 0
	, HHFleeingDV int default 0
	, HHAdultAge int default 0
	, HHParent int default 0
	, AC3Plus int default 0
	, Step varchar(10) not NULL
	, constraint pk_tlsa_HHID primary key clustered (HouseholdID)
	)

if object_id ('tlsa_Enrollment') is not NULL drop table tlsa_Enrollment 

create table tlsa_Enrollment (
	EnrollmentID varchar(32)
	, PersonalID varchar(32)
	, HouseholdID varchar(32)
	, RelationshipToHoH int
	, ProjectID varchar(32)
	, LSAProjectType int
	, EntryDate date
	, MoveInDate date
	, ExitDate date
	, LastBednight date
	, EntryAge int
	, ActiveAge int
	, Exit1Age int
	, Exit2Age int
	, DisabilityStatus int
	, DVStatus int
	, Active bit default 0
	, AHAR bit default 0
	, PITOctober bit default 0
	, PITJanuary bit default 0
	, PITApril bit default 0
	, PITJuly bit default 0
	, CH bit default 0
	, Step varchar(10) not NULL
	, constraint pk_tlsa_Enrollment primary key clustered (EnrollmentID)
	)


if object_id ('tlsa_Person') is not NULL drop table tlsa_Person

create table tlsa_Person (
-- client-level precursor to aggregate lsa_Person (LSAPerson.csv)
	PersonalID varchar(32) not NULL,
	HoHAdult int,
	CHStart date,
	LastActive date,
	Gender int,
	Race int,
	Ethnicity int,
	VetStatus int,
	DisabilityStatus int,
	CHTime int,
	CHTimeStatus int,
	DVStatus int,
	ESTAgeMin int default -1,
	ESTAgeMax int default -1,
	HHTypeEST int default -1,
	HoHEST int default -1,
	AdultEST int default -1,
	AHARAdultEST int default -1,
	HHChronicEST int default -1,
	HHVetEST int default -1,
	HHDisabilityEST int default -1,
	HHFleeingDVEST int default -1,
	HHAdultAgeAOEST int default -1,
	HHAdultAgeACEST int default -1,
	HHParentEST int default -1,
	AC3PlusEST int default -1,
	AHAREST int default -1,
	AHARHoHEST int default -1,
	RRHAgeMin int default -1,
	RRHAgeMax int default -1,
	HHTypeRRH int default -1,
	HoHRRH int default -1,
	AdultRRH int default -1,
	AHARAdultRRH int default -1,
	HHChronicRRH int default -1,
	HHVetRRH int default -1,
	HHDisabilityRRH int default -1,
	HHFleeingDVRRH int default -1,
	HHAdultAgeAORRH int default -1,
	HHAdultAgeACRRH int default -1,
	HHParentRRH int default -1,
	AC3PlusRRH int default -1,
	AHARRRH int default -1,
	AHARHoHRRH int default -1,
	PSHAgeMin int default -1,
	PSHAgeMax int default -1,
	HHTypePSH int default -1,
	HoHPSH int default -1,
	AdultPSH int default -1,
	AHARAdultPSH int default -1,
	HHChronicPSH int default -1,
	HHVetPSH int default -1,
	HHDisabilityPSH int default -1,
	HHFleeingDVPSH int default -1,
	HHAdultAgeAOPSH int default -1,
	HHAdultAgeACPSH int default -1,
	HHParentPSH int default -1,
	AC3PlusPSH int default -1,
	AHARPSH int default -1,
	AHARHoHPSH int default -1,
	SSNValid int,
	ReportID int,
	Step varchar(10) not NULL,
	constraint pk_tlsa_Person primary key clustered (PersonalID) 
	)
	;


if object_id ('ch_Exclude') is not NULL drop table ch_Exclude

	create table ch_Exclude(
	PersonalID varchar(32) not NULL,
	excludeDate date not NULL,
	Step varchar(10) not NULL,
	constraint pk_ch_Exclude primary key clustered (PersonalID, excludeDate) 
	)
	;

if object_id ('ch_Include') is not NULL drop table ch_Include
	
	create table ch_Include(
	PersonalID varchar(32) not NULL,
	ESSHStreetDate date not NULL,
	Step varchar(10) not NULL,
	constraint pk_ch_Include primary key clustered (PersonalID, ESSHStreetDate)
	)
	;
	
if object_id ('ch_Episodes') is not NULL drop table ch_Episodes
	create table ch_Episodes(
	PersonalID varchar(32),
	episodeStart date,
	episodeEnd date,
	episodeDays int null,
	Step varchar(10) not NULL,
	constraint pk_ch_Episodes primary key clustered (PersonalID, episodeStart)
	)
	;

if object_id ('tlsa_Household') is not NULL drop table tlsa_Household

create table tlsa_Household(
	HoHID varchar(32) not NULL,
	HHType int not null,
	FirstEntry date,
	LastInactive date,
	Stat int,
	StatEnrollmentID varchar(32),
	ReturnTime int,
	HHChronic int,
	HHVet int,
	HHDisability int,
	HHFleeingDV int,
	HoHRace int,
	HoHEthnicity int,
	HHAdult int,
	HHChild int,
	HHNoDOB int,
	HHAdultAge int,
	HHParent int,
	ESTStatus int,
	ESTGeography int,
	ESTLivingSit int,
	ESTDestination int,
	ESTChronic int,
	ESTVet int,
	ESTDisability int,
	ESTFleeingDV int,
	ESTAC3Plus int,
	ESTAdultAge int,
	ESTParent int,
	RRHStatus int,
	RRHMoveIn int,
	RRHGeography int,
	RRHLivingSit int,
	RRHDestination int,
	RRHPreMoveInDays int,
	RRHChronic int,
	RRHVet int,
	RRHDisability int,
	RRHFleeingDV int,
	RRHAC3Plus int,
	RRHAdultAge int,
	RRHParent int,
	PSHStatus int,
	PSHMoveIn int,
	PSHGeography int,
	PSHLivingSit int,
	PSHDestination int,
	PSHHousedDays int,
	PSHChronic int,
	PSHVet int,
	PSHDisability int,
	PSHFleeingDV int,
	PSHAC3Plus int,
	PSHAdultAge int,
	PSHParent int,
	ESDays int,
	THDays int,
	ESTDays int,
	RRHPSHPreMoveInDays int,
	RRHHousedDays int,
	SystemDaysNotPSHHoused int,
	SystemHomelessDays int,
	Other3917Days int,
	TotalHomelessDays int,
	SystemPath int,
	ESTAHAR int,
	RRHAHAR int,
	PSHAHAR int,
	ReportID int,
	Step varchar(10) not NULL,
	constraint pk_tlsa_Household primary key clustered (HoHID, HHType)
	)
	;

	if object_id ('sys_TimePadded') is not null drop table sys_TimePadded
	
	create table sys_TimePadded (
	HoHID varchar(32) not null
	, HHType int not null
	, Cohort int not null
	, StartDate date
	, EndDate date
	, Step varchar(10) not NULL
	)
	;

	if object_id ('sys_Time') is not null drop table sys_Time
	
	create table sys_Time (
		HoHID varchar(32)
		, HHType int
		, sysDate date
		, sysStatus int
		, Step varchar(10) not NULL
		, constraint pk_sys_Time primary key clustered (HoHID, HHType, sysDate)
		)
		;

	if object_id ('tlsa_Exit') is not NULL drop table tlsa_Exit
 
	create table tlsa_Exit(
		HoHID varchar(32) not null,
		HHType int not null,
		QualifyingExitHHID varchar(32),
		LastInactive date,
		Cohort int not NULL,
		Stat int,
		ExitFrom int,
		ExitTo int,
		ReturnTime int,
		HHVet int,
		HHChronic int,
		HHDisability int,
		HHFleeingDV int,
		HoHRace int,
		HoHEthnicity int,
		HHAdultAge int,
		HHParent int,
		AC3Plus int,
		SystemPath int,
		ReportID int not NULL,
		Step varchar(10) not NULL,
		constraint pk_tlsa_Exit primary key (Cohort, HoHID, HHType)
		)
		;

	if object_id ('tlsa_ExitHoHAdult') is not NULL drop table tlsa_ExitHoHAdult;
 
	create table tlsa_ExitHoHAdult(
		PersonalID varchar(32) not null,
		QualifyingExitHHID varchar(32),
		Cohort int not NULL,
		DisabilityStatus int,
		CHStart date,
		LastActive date,
		CHTime int,
		CHTimeStatus int,
		Step varchar(10) not NULL,
		constraint pk_tlsa_ExitHoHAdult primary key (PersonalID, QualifyingExitHHID, Cohort)
		)
		;

	if object_id ('tlsa_AveragePops') is not null drop table tlsa_AveragePops;

	create table tlsa_AveragePops (
		PopID int
		, Cohort int
		, HoHID varchar(32)
		, HHType int
		, Step varchar(10) not null)
		;

	if object_id ('tlsa_CountPops') is not null drop table tlsa_CountPops;

	create table tlsa_CountPops (
		PopID int
		, PersonalID varchar(32)
		, HouseholdID varchar(32)
		, Step varchar(10) not null)
		;

	if object_id ('ref_Calendar') is not null drop table ref_Calendar
	create table ref_Calendar (
		theDate date not null 
		, yyyy smallint
		, mm tinyint 
		, dd tinyint
		, month_name varchar(10)
		, day_name varchar(10) 
		, fy smallint
		, constraint pk_ref_Calendar primary key clustered (theDate) 
	)
	;

	--Populate ref_Calendar
	declare @start date = '2012-10-01'
	declare @end date = '2022-09-30'
	declare @i int = 0
	declare @total_days int = DATEDIFF(d, @start, @end) 

	while @i <= @total_days
	begin
			insert into ref_Calendar (theDate) 
			select cast(dateadd(d, @i, @start) as date) 
			set @i = @i + 1
	end

	update ref_Calendar
	set	month_name = datename(month, theDate),
		day_name = datename(weekday, theDate),
		yyyy = datepart(yyyy, theDate),
		mm = datepart(mm, theDate),
		dd = datepart(dd, theDate),
		fy = case when datepart(mm, theDate) between 10 and 12 then datepart(yyyy, theDate) + 1 
			else datepart(yyyy, theDate) end

	if object_id ('ref_RowValues') is not null drop table ref_RowValues
	create table ref_RowValues (
		RowID int not null 
		, Cohort int
		, Universe int 
		, SystemPath int
		, constraint pk_ref_RowValues primary key clustered (RowID, Cohort, Universe, SystemPath)
		)
;

	if object_id ('ref_RowPopulations') is not null drop table ref_RowPopulations
	create table ref_RowPopulations (
		RowMin int
		, RowMax int
		, ByPath int 
		, ByProject int
		, PopID int
		, Pop1 int
		, Pop2 int
		)
;

	if object_id ('ref_PopHHTypes') is not null drop table ref_PopHHTypes
	create table ref_PopHHTypes (
		PopID int not null
		, HHType int not null
		, constraint pk_ref_PopHHTypes primary key clustered (PopID, HHType)
)
;

insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (1,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (2,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (3,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (3,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (3,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (3,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (4,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (5,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (6,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (7,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (8,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (9,1,-1,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (10,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (11,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (12,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (13,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (14,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (15,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (16,1,-1,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (18,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (19,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (20,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (21,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (22,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (23,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-2,2,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-2,3,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-2,4,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-1,2,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-1,3,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,-1,4,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,0,2,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,0,3,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (24,0,4,1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-2,2,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-2,3,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-2,4,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-1,2,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-1,3,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,-1,4,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,0,2,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,0,3,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (25,0,4,2);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-2,2,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-2,3,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-2,4,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-1,2,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-1,3,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,-1,4,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,0,2,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,0,3,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (26,0,4,3);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-2,2,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-2,3,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-2,4,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-1,2,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-1,3,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,-1,4,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,0,2,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,0,3,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (27,0,4,4);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-2,2,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-2,3,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-2,4,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-1,2,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-1,3,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,-1,4,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,0,2,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,0,3,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (28,0,4,5);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-2,2,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-2,3,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-2,4,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-1,2,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-1,3,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,-1,4,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,0,2,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,0,3,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (29,0,4,6);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-2,2,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-2,3,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-2,4,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-1,2,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-1,3,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,-1,4,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,0,2,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,0,3,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (30,0,4,7);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-2,2,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-2,3,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-2,4,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-1,2,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-1,3,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,-1,4,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,0,2,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,0,3,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (31,0,4,8);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-2,2,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-2,3,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-2,4,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-1,2,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-1,3,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,-1,4,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,0,2,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,0,3,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (32,0,4,9);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-2,2,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-2,3,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-2,4,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-1,2,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-1,3,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,-1,4,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,0,2,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,0,3,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (33,0,4,10);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-2,2,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-2,3,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-2,4,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-1,2,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-1,3,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,-1,4,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,0,2,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,0,3,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (34,0,4,11);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-2,2,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-2,3,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-2,4,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-1,2,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-1,3,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,-1,4,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,0,2,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,0,3,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (35,0,4,12);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (36,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (37,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (37,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (37,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (38,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (38,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (38,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (39,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (39,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (39,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (40,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (40,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (40,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (41,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (41,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (41,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (42,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (42,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (42,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (43,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (43,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (43,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (44,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (44,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (44,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (45,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (45,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (45,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (46,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (46,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (46,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (47,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (47,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (47,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (48,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (48,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (48,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (49,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (49,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (49,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (50,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (50,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (50,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (51,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (51,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (51,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (52,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (52,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (52,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,1,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,10,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,11,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,12,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (53,13,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,1,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,10,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,11,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,12,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (54,13,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,1,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,10,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,11,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,12,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (55,13,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (56,1,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,11,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,12,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,13,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,14,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,15,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (57,1,16,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (58,20,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (59,20,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (60,20,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (61,20,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (62,1,10,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (63,0,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-2,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-2,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-2,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-1,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-1,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,-1,4,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,0,2,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,0,3,-1);
insert into ref_RowValues (RowID, Cohort, Universe, SystemPath) values (64,0,4,-1);
;
;
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,10,0,10);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,11,0,11);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,12,0,12);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,13,0,13);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,14,0,14);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,15,0,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,16,0,16);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,52,NULL,NULL,17,0,17);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,10,0,10);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,11,0,11);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,12,0,12);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,13,0,13);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,14,0,14);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,15,0,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,16,0,16);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,1,NULL,17,0,17);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,18,0,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,19,0,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,20,0,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,21,0,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,22,0,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,23,0,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,24,0,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,25,0,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,26,0,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,27,0,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,28,0,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,29,0,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,30,0,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,31,0,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,32,0,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,33,0,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,34,0,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,35,0,35);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,36,0,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1015,10,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1018,10,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1019,10,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1020,10,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1021,10,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1022,10,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1023,10,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1024,10,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1025,10,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1026,10,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1027,10,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1028,10,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1029,10,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1030,10,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1031,10,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1032,10,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1033,10,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1115,11,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1118,11,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1119,11,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1120,11,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1121,11,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1122,11,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1123,11,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1124,11,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1125,11,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1126,11,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1127,11,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1128,11,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1129,11,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1130,11,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1131,11,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1132,11,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1133,11,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1215,12,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1218,12,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1219,12,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1220,12,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1221,12,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1222,12,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1223,12,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1224,12,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1225,12,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1226,12,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1227,12,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1228,12,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1229,12,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1230,12,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1231,12,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1232,12,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1233,12,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1315,13,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1318,13,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1319,13,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1320,13,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1321,13,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1322,13,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1323,13,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1324,13,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1325,13,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1326,13,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1327,13,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1328,13,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1329,13,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1330,13,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1331,13,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1332,13,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1333,13,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1334,13,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1336,13,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1415,14,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1418,14,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1419,14,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1420,14,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1421,14,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1422,14,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1423,14,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1424,14,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1425,14,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1426,14,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1427,14,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1428,14,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1429,14,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1430,14,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1431,14,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1432,14,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1433,14,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1434,14,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1519,15,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1520,15,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1521,15,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1522,15,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1523,15,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1524,15,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1525,15,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1526,15,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1527,15,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1528,15,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1529,15,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1530,15,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1531,15,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1532,15,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1533,15,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1534,15,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1535,15,35);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (1,9,NULL,NULL,1536,15,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,18,0,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,19,0,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,20,0,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,21,0,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,22,0,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,23,0,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,24,0,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,25,0,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,26,0,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,27,0,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,28,0,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,29,0,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,30,0,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,31,0,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,32,0,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,33,0,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,34,0,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,35,0,35);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,36,0,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1018,10,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1019,10,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1020,10,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1021,10,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1022,10,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1023,10,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1024,10,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1025,10,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1026,10,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1027,10,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1028,10,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1029,10,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1030,10,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1031,10,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1032,10,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1033,10,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1118,11,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1119,11,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1120,11,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1121,11,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1122,11,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1123,11,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1124,11,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1125,11,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1126,11,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1127,11,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1128,11,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1129,11,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1130,11,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1131,11,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1132,11,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1133,11,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1218,12,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1219,12,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1220,12,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1221,12,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1222,12,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1223,12,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1224,12,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1225,12,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1226,12,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1227,12,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1228,12,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1229,12,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1230,12,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1231,12,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1232,12,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1233,12,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1318,13,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1319,13,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1320,13,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1321,13,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1322,13,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1323,13,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1324,13,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1325,13,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1326,13,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1327,13,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1328,13,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1329,13,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1330,13,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1331,13,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1332,13,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1333,13,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1334,13,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1336,13,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1418,14,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1419,14,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1420,14,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1421,14,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1422,14,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1423,14,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1424,14,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1425,14,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1426,14,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1427,14,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1428,14,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1429,14,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1430,14,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1431,14,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1432,14,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1433,14,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1434,14,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1519,15,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1520,15,20);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1521,15,21);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1522,15,22);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1523,15,23);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1524,15,24);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1525,15,25);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1526,15,26);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1527,15,27);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1528,15,28);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1529,15,29);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1530,15,30);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1531,15,31);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1532,15,32);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1533,15,33);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1534,15,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1535,15,35);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (23,23,NULL,NULL,1536,15,36);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,10,0,10);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,11,0,11);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,12,0,12);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,13,0,13);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,14,0,14);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,15,0,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,18,0,18);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,19,0,19);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,34,0,34);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (53,54,NULL,NULL,35,0,35);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,50,0,50);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,53,0,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,1176,0,1176);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,1177,0,1177);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,1276,0,1276);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,1277,0,1277);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,1176,0,1176);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,1177,0,1177);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,1276,0,1276);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,1,1277,0,1277);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,50,0,50);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,51,0,51);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,52,0,52);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,53,0,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,54,0,54);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,55,0,55);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,56,0,56);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,57,0,57);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,58,0,58);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,59,0,59);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,60,0,60);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,61,0,61);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,62,0,62);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,63,0,63);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,64,0,64);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,65,0,65);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,66,0,66);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,67,0,67);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,68,0,68);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,69,0,69);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,70,0,70);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,71,0,71);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,72,0,72);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,73,0,73);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,74,0,74);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,75,0,75);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,76,0,76);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,77,0,77);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,78,0,78);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,79,0,79);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,80,0,80);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,81,0,81);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,82,0,82);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5053,50,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5054,50,54);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5055,50,55);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5056,50,56);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5057,50,57);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5058,50,58);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5059,50,59);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5060,50,60);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5061,50,61);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5062,50,62);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5063,50,63);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5064,50,64);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5065,50,65);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5066,50,66);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5067,50,67);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5068,50,68);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5069,50,69);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5070,50,70);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5071,50,71);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5153,51,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5154,51,54);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5155,51,55);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5156,51,56);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5157,51,57);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5158,51,58);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5159,51,59);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5160,51,60);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5161,51,61);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5162,51,62);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5163,51,63);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5164,51,64);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5165,51,65);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5166,51,66);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5167,51,67);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5168,51,68);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5169,51,69);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5170,51,70);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5171,51,71);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5253,52,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5254,52,54);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5255,52,55);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5256,52,56);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5257,52,57);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5258,52,58);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5259,52,59);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5260,52,60);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5261,52,61);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5262,52,62);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5263,52,63);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5264,52,64);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5265,52,65);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5266,52,66);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5267,52,67);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5268,52,68);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5269,52,69);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5270,52,70);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (55,55,NULL,NULL,5271,52,71);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (56,56,NULL,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (56,56,NULL,NULL,10,0,10);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (56,56,NULL,NULL,11,0,11);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (57,57,NULL,NULL,50,0,50);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (57,57,NULL,NULL,53,0,53);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (58,62,NULL,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,0,0,0);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,10,0,10);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,11,0,11);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,12,0,12);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,13,0,13);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,14,0,14);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,15,0,15);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,16,0,16);
insert into ref_RowPopulations (RowMin, RowMax, ByPath, ByProject, PopID, Pop1, Pop2) values (63,64,NULL,NULL,17,0,17);

insert into ref_PopHHTypes (PopID, HHType) values (0,0);
insert into ref_PopHHTypes (PopID, HHType) values (0,1);
insert into ref_PopHHTypes (PopID, HHType) values (0,2);
insert into ref_PopHHTypes (PopID, HHType) values (0,3);
insert into ref_PopHHTypes (PopID, HHType) values (0,99);
insert into ref_PopHHTypes (PopID, HHType) values (10,1);
insert into ref_PopHHTypes (PopID, HHType) values (11,1);
insert into ref_PopHHTypes (PopID, HHType) values (12,2);
insert into ref_PopHHTypes (PopID, HHType) values (13,0);
insert into ref_PopHHTypes (PopID, HHType) values (13,1);
insert into ref_PopHHTypes (PopID, HHType) values (13,2);
insert into ref_PopHHTypes (PopID, HHType) values (13,99);
insert into ref_PopHHTypes (PopID, HHType) values (14,1);
insert into ref_PopHHTypes (PopID, HHType) values (15,0);
insert into ref_PopHHTypes (PopID, HHType) values (15,1);
insert into ref_PopHHTypes (PopID, HHType) values (15,2);
insert into ref_PopHHTypes (PopID, HHType) values (15,3);
insert into ref_PopHHTypes (PopID, HHType) values (15,99);
insert into ref_PopHHTypes (PopID, HHType) values (16,0);
insert into ref_PopHHTypes (PopID, HHType) values (16,1);
insert into ref_PopHHTypes (PopID, HHType) values (16,2);
insert into ref_PopHHTypes (PopID, HHType) values (16,3);
insert into ref_PopHHTypes (PopID, HHType) values (16,99);
insert into ref_PopHHTypes (PopID, HHType) values (17,0);
insert into ref_PopHHTypes (PopID, HHType) values (17,1);
insert into ref_PopHHTypes (PopID, HHType) values (17,2);
insert into ref_PopHHTypes (PopID, HHType) values (17,3);
insert into ref_PopHHTypes (PopID, HHType) values (17,99);
insert into ref_PopHHTypes (PopID, HHType) values (18,0);
insert into ref_PopHHTypes (PopID, HHType) values (18,1);
insert into ref_PopHHTypes (PopID, HHType) values (18,2);
insert into ref_PopHHTypes (PopID, HHType) values (18,3);
insert into ref_PopHHTypes (PopID, HHType) values (18,99);
insert into ref_PopHHTypes (PopID, HHType) values (19,0);
insert into ref_PopHHTypes (PopID, HHType) values (19,1);
insert into ref_PopHHTypes (PopID, HHType) values (19,2);
insert into ref_PopHHTypes (PopID, HHType) values (19,3);
insert into ref_PopHHTypes (PopID, HHType) values (19,99);
insert into ref_PopHHTypes (PopID, HHType) values (20,0);
insert into ref_PopHHTypes (PopID, HHType) values (20,1);
insert into ref_PopHHTypes (PopID, HHType) values (20,2);
insert into ref_PopHHTypes (PopID, HHType) values (20,3);
insert into ref_PopHHTypes (PopID, HHType) values (20,99);
insert into ref_PopHHTypes (PopID, HHType) values (21,0);
insert into ref_PopHHTypes (PopID, HHType) values (21,1);
insert into ref_PopHHTypes (PopID, HHType) values (21,2);
insert into ref_PopHHTypes (PopID, HHType) values (21,3);
insert into ref_PopHHTypes (PopID, HHType) values (21,99);
insert into ref_PopHHTypes (PopID, HHType) values (22,0);
insert into ref_PopHHTypes (PopID, HHType) values (22,1);
insert into ref_PopHHTypes (PopID, HHType) values (22,2);
insert into ref_PopHHTypes (PopID, HHType) values (22,3);
insert into ref_PopHHTypes (PopID, HHType) values (22,99);
insert into ref_PopHHTypes (PopID, HHType) values (23,0);
insert into ref_PopHHTypes (PopID, HHType) values (23,1);
insert into ref_PopHHTypes (PopID, HHType) values (23,2);
insert into ref_PopHHTypes (PopID, HHType) values (23,3);
insert into ref_PopHHTypes (PopID, HHType) values (23,99);
insert into ref_PopHHTypes (PopID, HHType) values (24,0);
insert into ref_PopHHTypes (PopID, HHType) values (24,1);
insert into ref_PopHHTypes (PopID, HHType) values (24,2);
insert into ref_PopHHTypes (PopID, HHType) values (24,3);
insert into ref_PopHHTypes (PopID, HHType) values (24,99);
insert into ref_PopHHTypes (PopID, HHType) values (25,0);
insert into ref_PopHHTypes (PopID, HHType) values (25,1);
insert into ref_PopHHTypes (PopID, HHType) values (25,2);
insert into ref_PopHHTypes (PopID, HHType) values (25,3);
insert into ref_PopHHTypes (PopID, HHType) values (25,99);
insert into ref_PopHHTypes (PopID, HHType) values (26,0);
insert into ref_PopHHTypes (PopID, HHType) values (26,1);
insert into ref_PopHHTypes (PopID, HHType) values (26,2);
insert into ref_PopHHTypes (PopID, HHType) values (26,3);
insert into ref_PopHHTypes (PopID, HHType) values (26,99);
insert into ref_PopHHTypes (PopID, HHType) values (27,0);
insert into ref_PopHHTypes (PopID, HHType) values (27,1);
insert into ref_PopHHTypes (PopID, HHType) values (27,2);
insert into ref_PopHHTypes (PopID, HHType) values (27,3);
insert into ref_PopHHTypes (PopID, HHType) values (27,99);
insert into ref_PopHHTypes (PopID, HHType) values (28,0);
insert into ref_PopHHTypes (PopID, HHType) values (28,1);
insert into ref_PopHHTypes (PopID, HHType) values (28,2);
insert into ref_PopHHTypes (PopID, HHType) values (28,3);
insert into ref_PopHHTypes (PopID, HHType) values (28,99);
insert into ref_PopHHTypes (PopID, HHType) values (29,0);
insert into ref_PopHHTypes (PopID, HHType) values (29,1);
insert into ref_PopHHTypes (PopID, HHType) values (29,2);
insert into ref_PopHHTypes (PopID, HHType) values (29,3);
insert into ref_PopHHTypes (PopID, HHType) values (29,99);
insert into ref_PopHHTypes (PopID, HHType) values (30,0);
insert into ref_PopHHTypes (PopID, HHType) values (30,1);
insert into ref_PopHHTypes (PopID, HHType) values (30,2);
insert into ref_PopHHTypes (PopID, HHType) values (30,3);
insert into ref_PopHHTypes (PopID, HHType) values (30,99);
insert into ref_PopHHTypes (PopID, HHType) values (31,0);
insert into ref_PopHHTypes (PopID, HHType) values (31,1);
insert into ref_PopHHTypes (PopID, HHType) values (31,2);
insert into ref_PopHHTypes (PopID, HHType) values (31,3);
insert into ref_PopHHTypes (PopID, HHType) values (31,99);
insert into ref_PopHHTypes (PopID, HHType) values (32,0);
insert into ref_PopHHTypes (PopID, HHType) values (32,1);
insert into ref_PopHHTypes (PopID, HHType) values (32,2);
insert into ref_PopHHTypes (PopID, HHType) values (32,3);
insert into ref_PopHHTypes (PopID, HHType) values (32,99);
insert into ref_PopHHTypes (PopID, HHType) values (33,0);
insert into ref_PopHHTypes (PopID, HHType) values (33,1);
insert into ref_PopHHTypes (PopID, HHType) values (33,2);
insert into ref_PopHHTypes (PopID, HHType) values (33,3);
insert into ref_PopHHTypes (PopID, HHType) values (33,99);
insert into ref_PopHHTypes (PopID, HHType) values (34,1);
insert into ref_PopHHTypes (PopID, HHType) values (35,3);
insert into ref_PopHHTypes (PopID, HHType) values (36,2);
insert into ref_PopHHTypes (PopID, HHType) values (50,0);
insert into ref_PopHHTypes (PopID, HHType) values (50,1);
insert into ref_PopHHTypes (PopID, HHType) values (50,2);
insert into ref_PopHHTypes (PopID, HHType) values (50,99);
insert into ref_PopHHTypes (PopID, HHType) values (51,2);
insert into ref_PopHHTypes (PopID, HHType) values (52,3);
insert into ref_PopHHTypes (PopID, HHType) values (53,0);
insert into ref_PopHHTypes (PopID, HHType) values (53,1);
insert into ref_PopHHTypes (PopID, HHType) values (53,2);
insert into ref_PopHHTypes (PopID, HHType) values (53,3);
insert into ref_PopHHTypes (PopID, HHType) values (53,99);
insert into ref_PopHHTypes (PopID, HHType) values (54,0);
insert into ref_PopHHTypes (PopID, HHType) values (54,1);
insert into ref_PopHHTypes (PopID, HHType) values (54,2);
insert into ref_PopHHTypes (PopID, HHType) values (54,3);
insert into ref_PopHHTypes (PopID, HHType) values (54,99);
insert into ref_PopHHTypes (PopID, HHType) values (55,0);
insert into ref_PopHHTypes (PopID, HHType) values (55,1);
insert into ref_PopHHTypes (PopID, HHType) values (55,2);
insert into ref_PopHHTypes (PopID, HHType) values (55,3);
insert into ref_PopHHTypes (PopID, HHType) values (55,99);
insert into ref_PopHHTypes (PopID, HHType) values (56,0);
insert into ref_PopHHTypes (PopID, HHType) values (56,1);
insert into ref_PopHHTypes (PopID, HHType) values (56,2);
insert into ref_PopHHTypes (PopID, HHType) values (56,3);
insert into ref_PopHHTypes (PopID, HHType) values (56,99);
insert into ref_PopHHTypes (PopID, HHType) values (57,0);
insert into ref_PopHHTypes (PopID, HHType) values (57,1);
insert into ref_PopHHTypes (PopID, HHType) values (57,2);
insert into ref_PopHHTypes (PopID, HHType) values (57,3);
insert into ref_PopHHTypes (PopID, HHType) values (57,99);
insert into ref_PopHHTypes (PopID, HHType) values (58,0);
insert into ref_PopHHTypes (PopID, HHType) values (58,1);
insert into ref_PopHHTypes (PopID, HHType) values (58,2);
insert into ref_PopHHTypes (PopID, HHType) values (58,3);
insert into ref_PopHHTypes (PopID, HHType) values (58,99);
insert into ref_PopHHTypes (PopID, HHType) values (59,0);
insert into ref_PopHHTypes (PopID, HHType) values (59,1);
insert into ref_PopHHTypes (PopID, HHType) values (59,2);
insert into ref_PopHHTypes (PopID, HHType) values (59,3);
insert into ref_PopHHTypes (PopID, HHType) values (59,99);
insert into ref_PopHHTypes (PopID, HHType) values (60,0);
insert into ref_PopHHTypes (PopID, HHType) values (60,1);
insert into ref_PopHHTypes (PopID, HHType) values (60,2);
insert into ref_PopHHTypes (PopID, HHType) values (60,3);
insert into ref_PopHHTypes (PopID, HHType) values (60,99);
insert into ref_PopHHTypes (PopID, HHType) values (61,0);
insert into ref_PopHHTypes (PopID, HHType) values (61,1);
insert into ref_PopHHTypes (PopID, HHType) values (61,2);
insert into ref_PopHHTypes (PopID, HHType) values (61,3);
insert into ref_PopHHTypes (PopID, HHType) values (61,99);
insert into ref_PopHHTypes (PopID, HHType) values (62,0);
insert into ref_PopHHTypes (PopID, HHType) values (62,1);
insert into ref_PopHHTypes (PopID, HHType) values (62,2);
insert into ref_PopHHTypes (PopID, HHType) values (62,3);
insert into ref_PopHHTypes (PopID, HHType) values (62,99);
insert into ref_PopHHTypes (PopID, HHType) values (63,0);
insert into ref_PopHHTypes (PopID, HHType) values (63,1);
insert into ref_PopHHTypes (PopID, HHType) values (63,2);
insert into ref_PopHHTypes (PopID, HHType) values (63,3);
insert into ref_PopHHTypes (PopID, HHType) values (63,99);
insert into ref_PopHHTypes (PopID, HHType) values (64,0);
insert into ref_PopHHTypes (PopID, HHType) values (64,1);
insert into ref_PopHHTypes (PopID, HHType) values (64,2);
insert into ref_PopHHTypes (PopID, HHType) values (64,3);
insert into ref_PopHHTypes (PopID, HHType) values (64,99);
insert into ref_PopHHTypes (PopID, HHType) values (65,0);
insert into ref_PopHHTypes (PopID, HHType) values (65,1);
insert into ref_PopHHTypes (PopID, HHType) values (65,2);
insert into ref_PopHHTypes (PopID, HHType) values (65,3);
insert into ref_PopHHTypes (PopID, HHType) values (65,99);
insert into ref_PopHHTypes (PopID, HHType) values (66,0);
insert into ref_PopHHTypes (PopID, HHType) values (66,1);
insert into ref_PopHHTypes (PopID, HHType) values (66,2);
insert into ref_PopHHTypes (PopID, HHType) values (66,3);
insert into ref_PopHHTypes (PopID, HHType) values (66,99);
insert into ref_PopHHTypes (PopID, HHType) values (67,0);
insert into ref_PopHHTypes (PopID, HHType) values (67,1);
insert into ref_PopHHTypes (PopID, HHType) values (67,2);
insert into ref_PopHHTypes (PopID, HHType) values (67,3);
insert into ref_PopHHTypes (PopID, HHType) values (67,99);
insert into ref_PopHHTypes (PopID, HHType) values (68,0);
insert into ref_PopHHTypes (PopID, HHType) values (68,1);
insert into ref_PopHHTypes (PopID, HHType) values (68,2);
insert into ref_PopHHTypes (PopID, HHType) values (68,3);
insert into ref_PopHHTypes (PopID, HHType) values (68,99);
insert into ref_PopHHTypes (PopID, HHType) values (69,0);
insert into ref_PopHHTypes (PopID, HHType) values (69,1);
insert into ref_PopHHTypes (PopID, HHType) values (69,2);
insert into ref_PopHHTypes (PopID, HHType) values (69,3);
insert into ref_PopHHTypes (PopID, HHType) values (69,99);
insert into ref_PopHHTypes (PopID, HHType) values (70,0);
insert into ref_PopHHTypes (PopID, HHType) values (70,1);
insert into ref_PopHHTypes (PopID, HHType) values (70,2);
insert into ref_PopHHTypes (PopID, HHType) values (70,3);
insert into ref_PopHHTypes (PopID, HHType) values (70,99);
insert into ref_PopHHTypes (PopID, HHType) values (71,0);
insert into ref_PopHHTypes (PopID, HHType) values (71,1);
insert into ref_PopHHTypes (PopID, HHType) values (71,2);
insert into ref_PopHHTypes (PopID, HHType) values (71,3);
insert into ref_PopHHTypes (PopID, HHType) values (71,99);
insert into ref_PopHHTypes (PopID, HHType) values (72,0);
insert into ref_PopHHTypes (PopID, HHType) values (72,2);
insert into ref_PopHHTypes (PopID, HHType) values (72,3);
insert into ref_PopHHTypes (PopID, HHType) values (72,99);
insert into ref_PopHHTypes (PopID, HHType) values (73,0);
insert into ref_PopHHTypes (PopID, HHType) values (73,2);
insert into ref_PopHHTypes (PopID, HHType) values (73,3);
insert into ref_PopHHTypes (PopID, HHType) values (73,99);
insert into ref_PopHHTypes (PopID, HHType) values (74,0);
insert into ref_PopHHTypes (PopID, HHType) values (74,2);
insert into ref_PopHHTypes (PopID, HHType) values (74,3);
insert into ref_PopHHTypes (PopID, HHType) values (74,99);
insert into ref_PopHHTypes (PopID, HHType) values (75,0);
insert into ref_PopHHTypes (PopID, HHType) values (75,2);
insert into ref_PopHHTypes (PopID, HHType) values (75,3);
insert into ref_PopHHTypes (PopID, HHType) values (75,99);
insert into ref_PopHHTypes (PopID, HHType) values (76,0);
insert into ref_PopHHTypes (PopID, HHType) values (76,1);
insert into ref_PopHHTypes (PopID, HHType) values (76,2);
insert into ref_PopHHTypes (PopID, HHType) values (76,99);
insert into ref_PopHHTypes (PopID, HHType) values (77,0);
insert into ref_PopHHTypes (PopID, HHType) values (77,1);
insert into ref_PopHHTypes (PopID, HHType) values (77,2);
insert into ref_PopHHTypes (PopID, HHType) values (77,99);
insert into ref_PopHHTypes (PopID, HHType) values (78,0);
insert into ref_PopHHTypes (PopID, HHType) values (78,1);
insert into ref_PopHHTypes (PopID, HHType) values (78,2);
insert into ref_PopHHTypes (PopID, HHType) values (78,99);
insert into ref_PopHHTypes (PopID, HHType) values (79,0);
insert into ref_PopHHTypes (PopID, HHType) values (79,1);
insert into ref_PopHHTypes (PopID, HHType) values (79,2);
insert into ref_PopHHTypes (PopID, HHType) values (79,99);
insert into ref_PopHHTypes (PopID, HHType) values (80,0);
insert into ref_PopHHTypes (PopID, HHType) values (80,1);
insert into ref_PopHHTypes (PopID, HHType) values (80,2);
insert into ref_PopHHTypes (PopID, HHType) values (80,99);
insert into ref_PopHHTypes (PopID, HHType) values (81,0);
insert into ref_PopHHTypes (PopID, HHType) values (81,1);
insert into ref_PopHHTypes (PopID, HHType) values (81,2);
insert into ref_PopHHTypes (PopID, HHType) values (81,99);
insert into ref_PopHHTypes (PopID, HHType) values (82,0);
insert into ref_PopHHTypes (PopID, HHType) values (82,1);
insert into ref_PopHHTypes (PopID, HHType) values (82,2);
insert into ref_PopHHTypes (PopID, HHType) values (82,99);
insert into ref_PopHHTypes (PopID, HHType) values (1015,1);
insert into ref_PopHHTypes (PopID, HHType) values (1018,1);
insert into ref_PopHHTypes (PopID, HHType) values (1019,1);
insert into ref_PopHHTypes (PopID, HHType) values (1020,1);
insert into ref_PopHHTypes (PopID, HHType) values (1021,1);
insert into ref_PopHHTypes (PopID, HHType) values (1022,1);
insert into ref_PopHHTypes (PopID, HHType) values (1023,1);
insert into ref_PopHHTypes (PopID, HHType) values (1024,1);
insert into ref_PopHHTypes (PopID, HHType) values (1025,1);
insert into ref_PopHHTypes (PopID, HHType) values (1026,1);
insert into ref_PopHHTypes (PopID, HHType) values (1027,1);
insert into ref_PopHHTypes (PopID, HHType) values (1028,1);
insert into ref_PopHHTypes (PopID, HHType) values (1029,1);
insert into ref_PopHHTypes (PopID, HHType) values (1030,1);
insert into ref_PopHHTypes (PopID, HHType) values (1031,1);
insert into ref_PopHHTypes (PopID, HHType) values (1032,1);
insert into ref_PopHHTypes (PopID, HHType) values (1033,1);
insert into ref_PopHHTypes (PopID, HHType) values (1115,1);
insert into ref_PopHHTypes (PopID, HHType) values (1118,1);
insert into ref_PopHHTypes (PopID, HHType) values (1119,1);
insert into ref_PopHHTypes (PopID, HHType) values (1120,1);
insert into ref_PopHHTypes (PopID, HHType) values (1121,1);
insert into ref_PopHHTypes (PopID, HHType) values (1122,1);
insert into ref_PopHHTypes (PopID, HHType) values (1123,1);
insert into ref_PopHHTypes (PopID, HHType) values (1124,1);
insert into ref_PopHHTypes (PopID, HHType) values (1125,1);
insert into ref_PopHHTypes (PopID, HHType) values (1126,1);
insert into ref_PopHHTypes (PopID, HHType) values (1127,1);
insert into ref_PopHHTypes (PopID, HHType) values (1128,1);
insert into ref_PopHHTypes (PopID, HHType) values (1129,1);
insert into ref_PopHHTypes (PopID, HHType) values (1130,1);
insert into ref_PopHHTypes (PopID, HHType) values (1131,1);
insert into ref_PopHHTypes (PopID, HHType) values (1132,1);
insert into ref_PopHHTypes (PopID, HHType) values (1133,1);
insert into ref_PopHHTypes (PopID, HHType) values (1176,1);
insert into ref_PopHHTypes (PopID, HHType) values (1177,1);
insert into ref_PopHHTypes (PopID, HHType) values (1215,2);
insert into ref_PopHHTypes (PopID, HHType) values (1218,2);
insert into ref_PopHHTypes (PopID, HHType) values (1219,2);
insert into ref_PopHHTypes (PopID, HHType) values (1220,2);
insert into ref_PopHHTypes (PopID, HHType) values (1221,2);
insert into ref_PopHHTypes (PopID, HHType) values (1222,2);
insert into ref_PopHHTypes (PopID, HHType) values (1223,2);
insert into ref_PopHHTypes (PopID, HHType) values (1224,2);
insert into ref_PopHHTypes (PopID, HHType) values (1225,2);
insert into ref_PopHHTypes (PopID, HHType) values (1226,2);
insert into ref_PopHHTypes (PopID, HHType) values (1227,2);
insert into ref_PopHHTypes (PopID, HHType) values (1228,2);
insert into ref_PopHHTypes (PopID, HHType) values (1229,2);
insert into ref_PopHHTypes (PopID, HHType) values (1230,2);
insert into ref_PopHHTypes (PopID, HHType) values (1231,2);
insert into ref_PopHHTypes (PopID, HHType) values (1232,2);
insert into ref_PopHHTypes (PopID, HHType) values (1233,2);
insert into ref_PopHHTypes (PopID, HHType) values (1276,2);
insert into ref_PopHHTypes (PopID, HHType) values (1277,2);
insert into ref_PopHHTypes (PopID, HHType) values (1315,0);
insert into ref_PopHHTypes (PopID, HHType) values (1315,1);
insert into ref_PopHHTypes (PopID, HHType) values (1315,2);
insert into ref_PopHHTypes (PopID, HHType) values (1315,99);
insert into ref_PopHHTypes (PopID, HHType) values (1318,0);
insert into ref_PopHHTypes (PopID, HHType) values (1318,1);
insert into ref_PopHHTypes (PopID, HHType) values (1318,2);
insert into ref_PopHHTypes (PopID, HHType) values (1318,99);
insert into ref_PopHHTypes (PopID, HHType) values (1319,0);
insert into ref_PopHHTypes (PopID, HHType) values (1319,1);
insert into ref_PopHHTypes (PopID, HHType) values (1319,2);
insert into ref_PopHHTypes (PopID, HHType) values (1319,99);
insert into ref_PopHHTypes (PopID, HHType) values (1320,0);
insert into ref_PopHHTypes (PopID, HHType) values (1320,1);
insert into ref_PopHHTypes (PopID, HHType) values (1320,2);
insert into ref_PopHHTypes (PopID, HHType) values (1320,99);
insert into ref_PopHHTypes (PopID, HHType) values (1321,0);
insert into ref_PopHHTypes (PopID, HHType) values (1321,1);
insert into ref_PopHHTypes (PopID, HHType) values (1321,2);
insert into ref_PopHHTypes (PopID, HHType) values (1321,99);
insert into ref_PopHHTypes (PopID, HHType) values (1322,0);
insert into ref_PopHHTypes (PopID, HHType) values (1322,1);
insert into ref_PopHHTypes (PopID, HHType) values (1322,2);
insert into ref_PopHHTypes (PopID, HHType) values (1322,99);
insert into ref_PopHHTypes (PopID, HHType) values (1323,0);
insert into ref_PopHHTypes (PopID, HHType) values (1323,1);
insert into ref_PopHHTypes (PopID, HHType) values (1323,2);
insert into ref_PopHHTypes (PopID, HHType) values (1323,99);
insert into ref_PopHHTypes (PopID, HHType) values (1324,0);
insert into ref_PopHHTypes (PopID, HHType) values (1324,1);
insert into ref_PopHHTypes (PopID, HHType) values (1324,2);
insert into ref_PopHHTypes (PopID, HHType) values (1324,99);
insert into ref_PopHHTypes (PopID, HHType) values (1325,0);
insert into ref_PopHHTypes (PopID, HHType) values (1325,1);
insert into ref_PopHHTypes (PopID, HHType) values (1325,2);
insert into ref_PopHHTypes (PopID, HHType) values (1325,99);
insert into ref_PopHHTypes (PopID, HHType) values (1326,0);
insert into ref_PopHHTypes (PopID, HHType) values (1326,1);
insert into ref_PopHHTypes (PopID, HHType) values (1326,2);
insert into ref_PopHHTypes (PopID, HHType) values (1326,99);
insert into ref_PopHHTypes (PopID, HHType) values (1327,0);
insert into ref_PopHHTypes (PopID, HHType) values (1327,1);
insert into ref_PopHHTypes (PopID, HHType) values (1327,2);
insert into ref_PopHHTypes (PopID, HHType) values (1327,99);
insert into ref_PopHHTypes (PopID, HHType) values (1328,0);
insert into ref_PopHHTypes (PopID, HHType) values (1328,1);
insert into ref_PopHHTypes (PopID, HHType) values (1328,2);
insert into ref_PopHHTypes (PopID, HHType) values (1328,99);
insert into ref_PopHHTypes (PopID, HHType) values (1329,0);
insert into ref_PopHHTypes (PopID, HHType) values (1329,1);
insert into ref_PopHHTypes (PopID, HHType) values (1329,2);
insert into ref_PopHHTypes (PopID, HHType) values (1329,99);
insert into ref_PopHHTypes (PopID, HHType) values (1330,0);
insert into ref_PopHHTypes (PopID, HHType) values (1330,1);
insert into ref_PopHHTypes (PopID, HHType) values (1330,2);
insert into ref_PopHHTypes (PopID, HHType) values (1330,99);
insert into ref_PopHHTypes (PopID, HHType) values (1331,0);
insert into ref_PopHHTypes (PopID, HHType) values (1331,1);
insert into ref_PopHHTypes (PopID, HHType) values (1331,2);
insert into ref_PopHHTypes (PopID, HHType) values (1331,99);
insert into ref_PopHHTypes (PopID, HHType) values (1332,0);
insert into ref_PopHHTypes (PopID, HHType) values (1332,1);
insert into ref_PopHHTypes (PopID, HHType) values (1332,2);
insert into ref_PopHHTypes (PopID, HHType) values (1332,99);
insert into ref_PopHHTypes (PopID, HHType) values (1333,0);
insert into ref_PopHHTypes (PopID, HHType) values (1333,1);
insert into ref_PopHHTypes (PopID, HHType) values (1333,2);
insert into ref_PopHHTypes (PopID, HHType) values (1333,99);
insert into ref_PopHHTypes (PopID, HHType) values (1334,1);
insert into ref_PopHHTypes (PopID, HHType) values (1336,2);
insert into ref_PopHHTypes (PopID, HHType) values (1415,1);
insert into ref_PopHHTypes (PopID, HHType) values (1418,1);
insert into ref_PopHHTypes (PopID, HHType) values (1419,1);
insert into ref_PopHHTypes (PopID, HHType) values (1420,1);
insert into ref_PopHHTypes (PopID, HHType) values (1421,1);
insert into ref_PopHHTypes (PopID, HHType) values (1422,1);
insert into ref_PopHHTypes (PopID, HHType) values (1423,1);
insert into ref_PopHHTypes (PopID, HHType) values (1424,1);
insert into ref_PopHHTypes (PopID, HHType) values (1425,1);
insert into ref_PopHHTypes (PopID, HHType) values (1426,1);
insert into ref_PopHHTypes (PopID, HHType) values (1427,1);
insert into ref_PopHHTypes (PopID, HHType) values (1428,1);
insert into ref_PopHHTypes (PopID, HHType) values (1429,1);
insert into ref_PopHHTypes (PopID, HHType) values (1430,1);
insert into ref_PopHHTypes (PopID, HHType) values (1431,1);
insert into ref_PopHHTypes (PopID, HHType) values (1432,1);
insert into ref_PopHHTypes (PopID, HHType) values (1433,1);
insert into ref_PopHHTypes (PopID, HHType) values (1434,1);
insert into ref_PopHHTypes (PopID, HHType) values (1519,0);
insert into ref_PopHHTypes (PopID, HHType) values (1519,1);
insert into ref_PopHHTypes (PopID, HHType) values (1519,2);
insert into ref_PopHHTypes (PopID, HHType) values (1519,3);
insert into ref_PopHHTypes (PopID, HHType) values (1519,99);
insert into ref_PopHHTypes (PopID, HHType) values (1520,0);
insert into ref_PopHHTypes (PopID, HHType) values (1520,1);
insert into ref_PopHHTypes (PopID, HHType) values (1520,2);
insert into ref_PopHHTypes (PopID, HHType) values (1520,3);
insert into ref_PopHHTypes (PopID, HHType) values (1520,99);
insert into ref_PopHHTypes (PopID, HHType) values (1521,0);
insert into ref_PopHHTypes (PopID, HHType) values (1521,1);
insert into ref_PopHHTypes (PopID, HHType) values (1521,2);
insert into ref_PopHHTypes (PopID, HHType) values (1521,3);
insert into ref_PopHHTypes (PopID, HHType) values (1521,99);
insert into ref_PopHHTypes (PopID, HHType) values (1522,0);
insert into ref_PopHHTypes (PopID, HHType) values (1522,1);
insert into ref_PopHHTypes (PopID, HHType) values (1522,2);
insert into ref_PopHHTypes (PopID, HHType) values (1522,3);
insert into ref_PopHHTypes (PopID, HHType) values (1522,99);
insert into ref_PopHHTypes (PopID, HHType) values (1523,0);
insert into ref_PopHHTypes (PopID, HHType) values (1523,1);
insert into ref_PopHHTypes (PopID, HHType) values (1523,2);
insert into ref_PopHHTypes (PopID, HHType) values (1523,3);
insert into ref_PopHHTypes (PopID, HHType) values (1523,99);
insert into ref_PopHHTypes (PopID, HHType) values (1524,0);
insert into ref_PopHHTypes (PopID, HHType) values (1524,1);
insert into ref_PopHHTypes (PopID, HHType) values (1524,2);
insert into ref_PopHHTypes (PopID, HHType) values (1524,3);
insert into ref_PopHHTypes (PopID, HHType) values (1524,99);
insert into ref_PopHHTypes (PopID, HHType) values (1525,0);
insert into ref_PopHHTypes (PopID, HHType) values (1525,1);
insert into ref_PopHHTypes (PopID, HHType) values (1525,2);
insert into ref_PopHHTypes (PopID, HHType) values (1525,3);
insert into ref_PopHHTypes (PopID, HHType) values (1525,99);
insert into ref_PopHHTypes (PopID, HHType) values (1526,0);
insert into ref_PopHHTypes (PopID, HHType) values (1526,1);
insert into ref_PopHHTypes (PopID, HHType) values (1526,2);
insert into ref_PopHHTypes (PopID, HHType) values (1526,3);
insert into ref_PopHHTypes (PopID, HHType) values (1526,99);
insert into ref_PopHHTypes (PopID, HHType) values (1527,0);
insert into ref_PopHHTypes (PopID, HHType) values (1527,1);
insert into ref_PopHHTypes (PopID, HHType) values (1527,2);
insert into ref_PopHHTypes (PopID, HHType) values (1527,3);
insert into ref_PopHHTypes (PopID, HHType) values (1527,99);
insert into ref_PopHHTypes (PopID, HHType) values (1528,0);
insert into ref_PopHHTypes (PopID, HHType) values (1528,1);
insert into ref_PopHHTypes (PopID, HHType) values (1528,2);
insert into ref_PopHHTypes (PopID, HHType) values (1528,3);
insert into ref_PopHHTypes (PopID, HHType) values (1528,99);
insert into ref_PopHHTypes (PopID, HHType) values (1529,0);
insert into ref_PopHHTypes (PopID, HHType) values (1529,1);
insert into ref_PopHHTypes (PopID, HHType) values (1529,2);
insert into ref_PopHHTypes (PopID, HHType) values (1529,3);
insert into ref_PopHHTypes (PopID, HHType) values (1529,99);
insert into ref_PopHHTypes (PopID, HHType) values (1530,0);
insert into ref_PopHHTypes (PopID, HHType) values (1530,1);
insert into ref_PopHHTypes (PopID, HHType) values (1530,2);
insert into ref_PopHHTypes (PopID, HHType) values (1530,3);
insert into ref_PopHHTypes (PopID, HHType) values (1530,99);
insert into ref_PopHHTypes (PopID, HHType) values (1531,0);
insert into ref_PopHHTypes (PopID, HHType) values (1531,1);
insert into ref_PopHHTypes (PopID, HHType) values (1531,2);
insert into ref_PopHHTypes (PopID, HHType) values (1531,3);
insert into ref_PopHHTypes (PopID, HHType) values (1531,99);
insert into ref_PopHHTypes (PopID, HHType) values (1532,0);
insert into ref_PopHHTypes (PopID, HHType) values (1532,1);
insert into ref_PopHHTypes (PopID, HHType) values (1532,2);
insert into ref_PopHHTypes (PopID, HHType) values (1532,3);
insert into ref_PopHHTypes (PopID, HHType) values (1532,99);
insert into ref_PopHHTypes (PopID, HHType) values (1533,0);
insert into ref_PopHHTypes (PopID, HHType) values (1533,1);
insert into ref_PopHHTypes (PopID, HHType) values (1533,2);
insert into ref_PopHHTypes (PopID, HHType) values (1533,3);
insert into ref_PopHHTypes (PopID, HHType) values (1533,99);
insert into ref_PopHHTypes (PopID, HHType) values (1534,1);
insert into ref_PopHHTypes (PopID, HHType) values (1535,3);
insert into ref_PopHHTypes (PopID, HHType) values (1536,2);
insert into ref_PopHHTypes (PopID, HHType) values (5053,0);
insert into ref_PopHHTypes (PopID, HHType) values (5053,1);
insert into ref_PopHHTypes (PopID, HHType) values (5053,2);
insert into ref_PopHHTypes (PopID, HHType) values (5053,99);
insert into ref_PopHHTypes (PopID, HHType) values (5054,0);
insert into ref_PopHHTypes (PopID, HHType) values (5054,1);
insert into ref_PopHHTypes (PopID, HHType) values (5054,2);
insert into ref_PopHHTypes (PopID, HHType) values (5054,99);
insert into ref_PopHHTypes (PopID, HHType) values (5055,0);
insert into ref_PopHHTypes (PopID, HHType) values (5055,1);
insert into ref_PopHHTypes (PopID, HHType) values (5055,2);
insert into ref_PopHHTypes (PopID, HHType) values (5055,99);
insert into ref_PopHHTypes (PopID, HHType) values (5056,0);
insert into ref_PopHHTypes (PopID, HHType) values (5056,1);
insert into ref_PopHHTypes (PopID, HHType) values (5056,2);
insert into ref_PopHHTypes (PopID, HHType) values (5056,99);
insert into ref_PopHHTypes (PopID, HHType) values (5057,0);
insert into ref_PopHHTypes (PopID, HHType) values (5057,1);
insert into ref_PopHHTypes (PopID, HHType) values (5057,2);
insert into ref_PopHHTypes (PopID, HHType) values (5057,99);
insert into ref_PopHHTypes (PopID, HHType) values (5058,0);
insert into ref_PopHHTypes (PopID, HHType) values (5058,1);
insert into ref_PopHHTypes (PopID, HHType) values (5058,2);
insert into ref_PopHHTypes (PopID, HHType) values (5058,99);
insert into ref_PopHHTypes (PopID, HHType) values (5059,0);
insert into ref_PopHHTypes (PopID, HHType) values (5059,1);
insert into ref_PopHHTypes (PopID, HHType) values (5059,2);
insert into ref_PopHHTypes (PopID, HHType) values (5059,99);
insert into ref_PopHHTypes (PopID, HHType) values (5060,0);
insert into ref_PopHHTypes (PopID, HHType) values (5060,1);
insert into ref_PopHHTypes (PopID, HHType) values (5060,2);
insert into ref_PopHHTypes (PopID, HHType) values (5060,99);
insert into ref_PopHHTypes (PopID, HHType) values (5061,0);
insert into ref_PopHHTypes (PopID, HHType) values (5061,1);
insert into ref_PopHHTypes (PopID, HHType) values (5061,2);
insert into ref_PopHHTypes (PopID, HHType) values (5061,99);
insert into ref_PopHHTypes (PopID, HHType) values (5062,0);
insert into ref_PopHHTypes (PopID, HHType) values (5062,1);
insert into ref_PopHHTypes (PopID, HHType) values (5062,2);
insert into ref_PopHHTypes (PopID, HHType) values (5062,99);
insert into ref_PopHHTypes (PopID, HHType) values (5063,0);
insert into ref_PopHHTypes (PopID, HHType) values (5063,1);
insert into ref_PopHHTypes (PopID, HHType) values (5063,2);
insert into ref_PopHHTypes (PopID, HHType) values (5063,99);
insert into ref_PopHHTypes (PopID, HHType) values (5064,0);
insert into ref_PopHHTypes (PopID, HHType) values (5064,1);
insert into ref_PopHHTypes (PopID, HHType) values (5064,2);
insert into ref_PopHHTypes (PopID, HHType) values (5064,99);
insert into ref_PopHHTypes (PopID, HHType) values (5065,0);
insert into ref_PopHHTypes (PopID, HHType) values (5065,1);
insert into ref_PopHHTypes (PopID, HHType) values (5065,2);
insert into ref_PopHHTypes (PopID, HHType) values (5065,99);
insert into ref_PopHHTypes (PopID, HHType) values (5066,0);
insert into ref_PopHHTypes (PopID, HHType) values (5066,1);
insert into ref_PopHHTypes (PopID, HHType) values (5066,2);
insert into ref_PopHHTypes (PopID, HHType) values (5066,99);
insert into ref_PopHHTypes (PopID, HHType) values (5067,0);
insert into ref_PopHHTypes (PopID, HHType) values (5067,1);
insert into ref_PopHHTypes (PopID, HHType) values (5067,2);
insert into ref_PopHHTypes (PopID, HHType) values (5067,99);
insert into ref_PopHHTypes (PopID, HHType) values (5068,0);
insert into ref_PopHHTypes (PopID, HHType) values (5068,1);
insert into ref_PopHHTypes (PopID, HHType) values (5068,2);
insert into ref_PopHHTypes (PopID, HHType) values (5068,99);
insert into ref_PopHHTypes (PopID, HHType) values (5069,0);
insert into ref_PopHHTypes (PopID, HHType) values (5069,1);
insert into ref_PopHHTypes (PopID, HHType) values (5069,2);
insert into ref_PopHHTypes (PopID, HHType) values (5069,99);
insert into ref_PopHHTypes (PopID, HHType) values (5070,0);
insert into ref_PopHHTypes (PopID, HHType) values (5070,1);
insert into ref_PopHHTypes (PopID, HHType) values (5070,2);
insert into ref_PopHHTypes (PopID, HHType) values (5070,99);
insert into ref_PopHHTypes (PopID, HHType) values (5071,0);
insert into ref_PopHHTypes (PopID, HHType) values (5071,1);
insert into ref_PopHHTypes (PopID, HHType) values (5071,2);
insert into ref_PopHHTypes (PopID, HHType) values (5071,99);
insert into ref_PopHHTypes (PopID, HHType) values (5153,2);
insert into ref_PopHHTypes (PopID, HHType) values (5154,2);
insert into ref_PopHHTypes (PopID, HHType) values (5155,2);
insert into ref_PopHHTypes (PopID, HHType) values (5156,2);
insert into ref_PopHHTypes (PopID, HHType) values (5157,2);
insert into ref_PopHHTypes (PopID, HHType) values (5158,2);
insert into ref_PopHHTypes (PopID, HHType) values (5159,2);
insert into ref_PopHHTypes (PopID, HHType) values (5160,2);
insert into ref_PopHHTypes (PopID, HHType) values (5161,2);
insert into ref_PopHHTypes (PopID, HHType) values (5162,2);
insert into ref_PopHHTypes (PopID, HHType) values (5163,2);
insert into ref_PopHHTypes (PopID, HHType) values (5164,2);
insert into ref_PopHHTypes (PopID, HHType) values (5165,2);
insert into ref_PopHHTypes (PopID, HHType) values (5166,2);
insert into ref_PopHHTypes (PopID, HHType) values (5167,2);
insert into ref_PopHHTypes (PopID, HHType) values (5168,2);
insert into ref_PopHHTypes (PopID, HHType) values (5169,2);
insert into ref_PopHHTypes (PopID, HHType) values (5170,2);
insert into ref_PopHHTypes (PopID, HHType) values (5171,2);
insert into ref_PopHHTypes (PopID, HHType) values (5253,3);
insert into ref_PopHHTypes (PopID, HHType) values (5254,3);
insert into ref_PopHHTypes (PopID, HHType) values (5255,3);
insert into ref_PopHHTypes (PopID, HHType) values (5256,3);
insert into ref_PopHHTypes (PopID, HHType) values (5257,3);
insert into ref_PopHHTypes (PopID, HHType) values (5258,3);
insert into ref_PopHHTypes (PopID, HHType) values (5259,3);
insert into ref_PopHHTypes (PopID, HHType) values (5260,3);
insert into ref_PopHHTypes (PopID, HHType) values (5261,3);
insert into ref_PopHHTypes (PopID, HHType) values (5262,3);
insert into ref_PopHHTypes (PopID, HHType) values (5263,3);
insert into ref_PopHHTypes (PopID, HHType) values (5264,3);
insert into ref_PopHHTypes (PopID, HHType) values (5265,3);
insert into ref_PopHHTypes (PopID, HHType) values (5266,3);
insert into ref_PopHHTypes (PopID, HHType) values (5267,3);
insert into ref_PopHHTypes (PopID, HHType) values (5268,3);
insert into ref_PopHHTypes (PopID, HHType) values (5269,3);
insert into ref_PopHHTypes (PopID, HHType) values (5270,3);
insert into ref_PopHHTypes (PopID, HHType) values (5271,3);



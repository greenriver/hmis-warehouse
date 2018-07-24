SqlServerBase.connection.execute (<<~SQL);
  SET ANSI_NULLS ON
SQL
SqlServerBase.connection.execute (<<~SQL);
  SET QUOTED_IDENTIFIER ON
SQL
SqlServerBase.connection.execute (<<~SQL);

  if object_id ('active_Enrollment') is not null drop table active_Enrollment
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

  if object_id ('active_Household') is not null drop table active_Household
  CREATE TABLE dbo.active_Household(
    HouseholdID varchar(32) NOT NULL,
    HoHID varchar(32) NULL,
    HHType int NULL,
    ProjectID int NULL,
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

  if object_id ('ch_Enrollment') is not null drop table ch_Enrollment
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

  if object_id ('dq_Enrollment') is not null drop table dq_Enrollment
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

  if object_id ('ex_Enrollment') is not null drop table ex_Enrollment
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
  --INSERT [dbo].[lsa_Report] ([ReportID], [ReportDate], [ReportStart], [ReportEnd], [ReportCoC], [SoftwareVendor], [SoftwareName], [VendorContact], [VendorEmail], [LSAScope]) VALUES (1009, CAST(N'2018-05-07T17:47:35.977' AS DateTime), CAST(N'2016-10-01' AS Date), CAST(N'2017-09-30' AS Date), N'XX-500', N'Tamale Inc.', N'Tamale Online', N'Molly', N'molly@squarepegdata.com', 1)

  if object_id ('sys_Enrollment') is not null drop table sys_Enrollment
  CREATE TABLE dbo.sys_Enrollment(
    HoHID varchar(32) NULL,
    HHType int NULL,
    EnrollmentID varchar(32) NULL,
    ProjectType int NULL,
    EntryDate date NULL,
    MoveInDate date NULL,
    ExitDate date NULL,
    Active bit NULL
  )
  ;

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
    CohortEnd date NULL
  )
  ;

  if object_id ('tmp_Exit') is not null drop table tmp_Exit
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

  if object_id ('tmp_Household') is not null drop table tmp_Household
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

  if object_id ('tmp_Person') is not null drop table tmp_Person
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
SQL
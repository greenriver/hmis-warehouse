# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161107160154) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"

  create_table "Client", force: :cascade do |t|
    t.string   "PersonalID",           limit: 4000
    t.string   "FirstName",            limit: 150
    t.string   "MiddleName",           limit: 150
    t.string   "LastName",             limit: 150
    t.string   "NameSuffix",           limit: 50
    t.integer  "NameDataQuality"
    t.string   "SSN"
    t.integer  "SSNDataQuality"
    t.date     "DOB"
    t.integer  "DOBDataQuality"
    t.integer  "AmIndAKNative"
    t.integer  "Asian"
    t.integer  "BlackAfAmerican"
    t.integer  "NativeHIOtherPacific"
    t.integer  "White"
    t.integer  "RaceNone"
    t.integer  "Ethnicity"
    t.integer  "Gender"
    t.string   "OtherGender"
    t.integer  "VeteranStatus"
    t.integer  "YearEnteredService"
    t.integer  "YearSeparated"
    t.integer  "WorldWarII"
    t.integer  "KoreanWar"
    t.integer  "VietnamWar"
    t.integer  "DesertStorm"
    t.integer  "AfghanistanOEF"
    t.integer  "IraqOIF"
    t.integer  "IraqOND"
    t.integer  "OtherTheater"
    t.integer  "MilitaryBranch"
    t.integer  "DischargeStatus"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID"
    t.datetime "DateDeleted"
    t.string   "ExportID",             limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Client", ["DateCreated"], name: "client_date_created", using: :btree
  add_index "Client", ["DateUpdated"], name: "client_date_updated", using: :btree
  add_index "Client", ["ExportID"], name: "client_export_id", using: :btree
  add_index "Client", ["FirstName"], name: "client_first_name", using: :btree
  add_index "Client", ["LastName"], name: "client_last_name", using: :btree
  add_index "Client", ["PersonalID"], name: "client_personal_id", using: :btree
  add_index "Client", ["data_source_id", "PersonalID"], name: "index_Client_on_data_source_id_and_PersonalID", using: :btree
  add_index "Client", ["data_source_id"], name: "index_Client_on_data_source_id", using: :btree

  create_table "Disabilities", force: :cascade do |t|
    t.string   "DisabilitiesID",       limit: 4000
    t.string   "ProjectEntryID",       limit: 4000
    t.string   "PersonalID",           limit: 4000
    t.date     "InformationDate"
    t.integer  "DisabilityType"
    t.integer  "DisabilityResponse"
    t.integer  "IndefiniteAndImpairs"
    t.integer  "DocumentationOnFile"
    t.integer  "ReceivingServices"
    t.integer  "PATHHowConfirmed"
    t.integer  "PATHSMIInformation"
    t.integer  "TCellCountAvailable"
    t.integer  "TCellCount"
    t.integer  "TCellSource"
    t.integer  "ViralLoadAvailable"
    t.integer  "ViralLoad"
    t.integer  "ViralLoadSource"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",               limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",             limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Disabilities", ["DateCreated"], name: "disabilities_date_created", using: :btree
  add_index "Disabilities", ["DateUpdated"], name: "disabilities_date_updated", using: :btree
  add_index "Disabilities", ["ExportID"], name: "disabilities_export_id", using: :btree
  add_index "Disabilities", ["PersonalID"], name: "index_Disabilities_on_PersonalID", using: :btree
  add_index "Disabilities", ["data_source_id", "PersonalID"], name: "index_Disabilities_on_data_source_id_and_PersonalID", using: :btree
  add_index "Disabilities", ["data_source_id"], name: "index_Disabilities_on_data_source_id", using: :btree

  create_table "EmploymentEducation", force: :cascade do |t|
    t.string   "EmploymentEducationID", limit: 4000
    t.string   "ProjectEntryID",        limit: 4000
    t.string   "PersonalID",            limit: 4000
    t.date     "InformationDate"
    t.integer  "LastGradeCompleted"
    t.integer  "SchoolStatus"
    t.integer  "Employed"
    t.integer  "EmploymentType"
    t.integer  "NotEmployedReason"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",              limit: 4000
    t.integer  "data_source_id"
  end

  add_index "EmploymentEducation", ["DateCreated"], name: "employment_education_date_created", using: :btree
  add_index "EmploymentEducation", ["DateUpdated"], name: "employment_education_date_updated", using: :btree
  add_index "EmploymentEducation", ["ExportID"], name: "employment_education_export_id", using: :btree
  add_index "EmploymentEducation", ["PersonalID"], name: "index_EmploymentEducation_on_PersonalID", using: :btree
  add_index "EmploymentEducation", ["data_source_id", "EmploymentEducationID"], name: "unk_EmploymentEducation", unique: true, using: :btree
  add_index "EmploymentEducation", ["data_source_id", "PersonalID"], name: "index_EmploymentEducation_on_data_source_id_and_PersonalID", using: :btree

  create_table "Enrollment", force: :cascade do |t|
    t.string   "ProjectEntryID",                               limit: 4000
    t.string   "PersonalID",                                   limit: 4000
    t.string   "ProjectID",                                    limit: 4000
    t.date     "EntryDate"
    t.string   "HouseholdID",                                  limit: 4000
    t.integer  "RelationshipToHoH"
    t.integer  "ResidencePrior"
    t.string   "OtherResidencePrior",                          limit: 4000
    t.integer  "ResidencePriorLengthOfStay"
    t.integer  "DisablingCondition"
    t.integer  "EntryFromStreetESSH"
    t.date     "DateToStreetESSH"
    t.integer  "ContinuouslyHomelessOneYear"
    t.integer  "TimesHomelessPastThreeYears"
    t.integer  "MonthsHomelessPastThreeYears"
    t.integer  "MonthsHomelessThisTime"
    t.integer  "StatusDocumented"
    t.integer  "HousingStatus"
    t.date     "DateOfEngagement"
    t.integer  "InPermanentHousing"
    t.date     "ResidentialMoveInDate"
    t.date     "DateOfPATHStatus"
    t.integer  "ClientEnrolledInPATH"
    t.integer  "ReasonNotEnrolled"
    t.integer  "WorstHousingSituation"
    t.integer  "PercentAMI"
    t.string   "LastPermanentStreet",                          limit: 4000
    t.string   "LastPermanentCity",                            limit: 50
    t.string   "LastPermanentState",                           limit: 2
    t.string   "LastPermanentZIP",                             limit: 10
    t.integer  "AddressDataQuality"
    t.date     "DateOfBCPStatus"
    t.integer  "FYSBYouth"
    t.integer  "ReasonNoServices"
    t.integer  "SexualOrientation"
    t.integer  "FormerWardChildWelfare"
    t.integer  "ChildWelfareYears"
    t.integer  "ChildWelfareMonths"
    t.integer  "FormerWardJuvenileJustice"
    t.integer  "JuvenileJusticeYears"
    t.integer  "JuvenileJusticeMonths"
    t.integer  "HouseholdDynamics"
    t.integer  "SexualOrientationGenderIDYouth"
    t.integer  "SexualOrientationGenderIDFam"
    t.integer  "HousingIssuesYouth"
    t.integer  "HousingIssuesFam"
    t.integer  "SchoolEducationalIssuesYouth"
    t.integer  "SchoolEducationalIssuesFam"
    t.integer  "UnemploymentYouth"
    t.integer  "UnemploymentFam"
    t.integer  "MentalHealthIssuesYouth"
    t.integer  "MentalHealthIssuesFam"
    t.integer  "HealthIssuesYouth"
    t.integer  "HealthIssuesFam"
    t.integer  "PhysicalDisabilityYouth"
    t.integer  "PhysicalDisabilityFam"
    t.integer  "MentalDisabilityYouth"
    t.integer  "MentalDisabilityFam"
    t.integer  "AbuseAndNeglectYouth"
    t.integer  "AbuseAndNeglectFam"
    t.integer  "AlcoholDrugAbuseYouth"
    t.integer  "AlcoholDrugAbuseFam"
    t.integer  "InsufficientIncome"
    t.integer  "ActiveMilitaryParent"
    t.integer  "IncarceratedParent"
    t.integer  "IncarceratedParentStatus"
    t.integer  "ReferralSource"
    t.integer  "CountOutreachReferralApproaches"
    t.integer  "ExchangeForSex"
    t.integer  "ExchangeForSexPastThreeMonths"
    t.integer  "CountOfExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer  "WorkPlaceViolenceThreats"
    t.integer  "WorkplacePromiseDifference"
    t.integer  "CoercedToContinueWork"
    t.integer  "LaborExploitPastThreeMonths"
    t.integer  "HPScreeningScore"
    t.integer  "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",                                     limit: 4000
    t.integer  "data_source_id"
    t.integer  "LOSUnderThreshold"
    t.integer  "PreviousStreetESSH"
    t.integer  "UrgentReferral"
    t.integer  "TimeToHousingLoss"
    t.integer  "ZeroIncome"
    t.integer  "AnnualPercentAMI"
    t.integer  "FinancialChange"
    t.integer  "HouseholdChange"
    t.integer  "EvictionHistory"
    t.integer  "SubsidyAtRisk"
    t.integer  "LiteralHomelessHistory"
    t.integer  "DisabledHoH"
    t.integer  "CriminalRecord"
    t.integer  "SexOffender"
    t.integer  "DependentUnder6"
    t.integer  "SingleParent"
    t.integer  "HH5Plus"
    t.integer  "IraqAfghanistan"
    t.integer  "FemVet"
    t.integer  "ThresholdScore"
    t.integer  "ERVisits"
    t.integer  "JailNights"
    t.integer  "HospitalNights"
  end

  add_index "Enrollment", ["DateCreated"], name: "enrollment_date_created", using: :btree
  add_index "Enrollment", ["DateDeleted"], name: "index_Enrollment_on_DateDeleted", using: :btree
  add_index "Enrollment", ["DateUpdated"], name: "enrollment_date_updated", using: :btree
  add_index "Enrollment", ["EntryDate"], name: "index_Enrollment_on_EntryDate", using: :btree
  add_index "Enrollment", ["ExportID"], name: "enrollment_export_id", using: :btree
  add_index "Enrollment", ["PersonalID"], name: "index_Enrollment_on_PersonalID", using: :btree
  add_index "Enrollment", ["ProjectEntryID"], name: "index_Enrollment_on_ProjectEntryID", using: :btree
  add_index "Enrollment", ["ProjectID"], name: "index_Enrollment_on_ProjectID", using: :btree
  add_index "Enrollment", ["data_source_id", "PersonalID"], name: "index_Enrollment_on_data_source_id_and_PersonalID", using: :btree

  create_table "EnrollmentCoC", force: :cascade do |t|
    t.string   "EnrollmentCoCID",     limit: 4000
    t.string   "ProjectEntryID",      limit: 4000
    t.string   "ProjectID",           limit: 4000
    t.string   "PersonalID",          limit: 4000
    t.date     "InformationDate"
    t.string   "CoCCode",             limit: 50
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",              limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",            limit: 4000
    t.integer  "data_source_id"
    t.string   "HouseholdID",         limit: 32
  end

  add_index "EnrollmentCoC", ["DateCreated"], name: "enrollment_coc_date_created", using: :btree
  add_index "EnrollmentCoC", ["DateUpdated"], name: "enrollment_coc_date_updated", using: :btree
  add_index "EnrollmentCoC", ["EnrollmentCoCID"], name: "index_EnrollmentCoC_on_EnrollmentCoCID", using: :btree
  add_index "EnrollmentCoC", ["ExportID"], name: "enrollment_coc_export_id", using: :btree
  add_index "EnrollmentCoC", ["data_source_id", "PersonalID"], name: "index_EnrollmentCoC_on_data_source_id_and_PersonalID", using: :btree
  add_index "EnrollmentCoC", ["data_source_id"], name: "index_EnrollmentCoC_on_data_source_id", using: :btree

  create_table "Exit", force: :cascade do |t|
    t.string   "ExitID",                       limit: 4000
    t.string   "ProjectEntryID",               limit: 4000
    t.string   "PersonalID",                   limit: 4000
    t.date     "ExitDate"
    t.integer  "Destination"
    t.string   "OtherDestination",             limit: 4000
    t.integer  "AssessmentDisposition"
    t.string   "OtherDisposition",             limit: 4000
    t.integer  "HousingAssessment"
    t.integer  "SubsidyInformation"
    t.integer  "ConnectionWithSOAR"
    t.integer  "WrittenAftercarePlan"
    t.integer  "AssistanceMainstreamBenefits"
    t.integer  "PermanentHousingPlacement"
    t.integer  "TemporaryShelterPlacement"
    t.integer  "ExitCounseling"
    t.integer  "FurtherFollowUpServices"
    t.integer  "ScheduledFollowUpContacts"
    t.integer  "ResourcePackage"
    t.integer  "OtherAftercarePlanOrAction"
    t.integer  "ProjectCompletionStatus"
    t.integer  "EarlyExitReason"
    t.integer  "FamilyReunificationAchieved"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",                     limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Exit", ["DateCreated"], name: "exit_date_created", using: :btree
  add_index "Exit", ["DateDeleted"], name: "index_Exit_on_DateDeleted", using: :btree
  add_index "Exit", ["DateUpdated"], name: "exit_date_updated", using: :btree
  add_index "Exit", ["ExitDate"], name: "index_Exit_on_ExitDate", using: :btree
  add_index "Exit", ["ExportID"], name: "exit_export_id", using: :btree
  add_index "Exit", ["PersonalID"], name: "index_Exit_on_PersonalID", using: :btree
  add_index "Exit", ["ProjectEntryID"], name: "index_Exit_on_ProjectEntryID", using: :btree
  add_index "Exit", ["data_source_id", "PersonalID"], name: "index_Exit_on_data_source_id_and_PersonalID", using: :btree

  create_table "Export", force: :cascade do |t|
    t.string   "ExportID",               limit: 4000
    t.string   "SourceID",               limit: 4000
    t.string   "SourceName",             limit: 4000
    t.string   "SourceContactFirst",     limit: 4000
    t.string   "SourceContactLast",      limit: 4000
    t.string   "SourceContactPhone",     limit: 4000
    t.string   "SourceContactExtension", limit: 4000
    t.string   "SourceContactEmail",     limit: 4000
    t.datetime "ExportDate"
    t.date     "ExportStartDate"
    t.date     "ExportEndDate"
    t.string   "SoftwareName",           limit: 4000
    t.string   "SoftwareVersion",        limit: 4000
    t.integer  "ExportPeriodType"
    t.integer  "ExportDirective"
    t.integer  "HashStatus"
    t.integer  "data_source_id"
    t.integer  "SourceType"
  end

  add_index "Export", ["ExportID"], name: "export_export_id", using: :btree
  add_index "Export", ["data_source_id", "ExportID"], name: "unk_Export", unique: true, using: :btree

  create_table "Funder", force: :cascade do |t|
    t.string   "FunderID",       limit: 4000
    t.string   "ProjectID",      limit: 4000
    t.string   "Funder",         limit: 4000
    t.string   "GrantID",        limit: 4000
    t.date     "StartDate"
    t.date     "EndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",       limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Funder", ["DateCreated"], name: "funder_date_created", using: :btree
  add_index "Funder", ["DateUpdated"], name: "funder_date_updated", using: :btree
  add_index "Funder", ["ExportID"], name: "funder_export_id", using: :btree
  add_index "Funder", ["data_source_id", "FunderID"], name: "unk_Funder", unique: true, using: :btree

  create_table "HealthAndDV", force: :cascade do |t|
    t.string   "HealthAndDVID",          limit: 4000
    t.string   "ProjectEntryID",         limit: 4000
    t.string   "PersonalID",             limit: 4000
    t.date     "InformationDate"
    t.integer  "DomesticViolenceVictim"
    t.integer  "WhenOccurred"
    t.integer  "CurrentlyFleeing"
    t.integer  "GeneralHealthStatus"
    t.integer  "DentalHealthStatus"
    t.integer  "MentalHealthStatus"
    t.integer  "PregnancyStatus"
    t.date     "DueDate"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",               limit: 4000
    t.integer  "data_source_id"
  end

  add_index "HealthAndDV", ["DateCreated"], name: "health_and_dv_date_created", using: :btree
  add_index "HealthAndDV", ["DateUpdated"], name: "health_and_dv_date_updated", using: :btree
  add_index "HealthAndDV", ["ExportID"], name: "health_and_dv_export_id", using: :btree
  add_index "HealthAndDV", ["PersonalID"], name: "index_HealthAndDV_on_PersonalID", using: :btree
  add_index "HealthAndDV", ["data_source_id", "HealthAndDVID"], name: "unk_HealthAndDV", unique: true, using: :btree
  add_index "HealthAndDV", ["data_source_id", "PersonalID"], name: "index_HealthAndDV_on_data_source_id_and_PersonalID", using: :btree

  create_table "IncomeBenefits", force: :cascade do |t|
    t.string   "IncomeBenefitsID",             limit: 4000
    t.string   "ProjectEntryID",               limit: 4000
    t.string   "PersonalID",                   limit: 4000
    t.date     "InformationDate"
    t.integer  "IncomeFromAnySource"
    t.decimal  "TotalMonthlyIncome",                        precision: 18
    t.integer  "Earned"
    t.decimal  "EarnedAmount",                              precision: 18
    t.integer  "Unemployment"
    t.decimal  "UnemploymentAmount",                        precision: 18
    t.integer  "SSI"
    t.decimal  "SSIAmount",                                 precision: 18
    t.integer  "SSDI"
    t.decimal  "SSDIAmount",                                precision: 18
    t.integer  "VADisabilityService"
    t.decimal  "VADisabilityServiceAmount",                 precision: 18
    t.integer  "VADisabilityNonService"
    t.decimal  "VADisabilityNonServiceAmount",              precision: 18
    t.integer  "PrivateDisability"
    t.decimal  "PrivateDisabilityAmount",                   precision: 18
    t.integer  "WorkersComp"
    t.decimal  "WorkersCompAmount",                         precision: 18
    t.integer  "TANF"
    t.decimal  "TANFAmount",                                precision: 18
    t.integer  "GA"
    t.decimal  "GAAmount",                                  precision: 18
    t.integer  "SocSecRetirement"
    t.decimal  "SocSecRetirementAmount",                    precision: 18
    t.integer  "Pension"
    t.decimal  "PensionAmount",                             precision: 18
    t.integer  "ChildSupport"
    t.decimal  "ChildSupportAmount",                        precision: 18
    t.integer  "Alimony"
    t.decimal  "AlimonyAmount",                             precision: 18
    t.integer  "OtherIncomeSource"
    t.decimal  "OtherIncomeAmount",                         precision: 18
    t.string   "OtherIncomeSourceIdentify",    limit: 4000
    t.integer  "BenefitsFromAnySource"
    t.integer  "SNAP"
    t.integer  "WIC"
    t.integer  "TANFChildCare"
    t.integer  "TANFTransportation"
    t.integer  "OtherTANF"
    t.integer  "RentalAssistanceOngoing"
    t.integer  "RentalAssistanceTemp"
    t.integer  "OtherBenefitsSource"
    t.string   "OtherBenefitsSourceIdentify",  limit: 4000
    t.integer  "InsuranceFromAnySource"
    t.integer  "Medicaid"
    t.integer  "NoMedicaidReason"
    t.integer  "Medicare"
    t.integer  "NoMedicareReason"
    t.integer  "SCHIP"
    t.integer  "NoSCHIPReason"
    t.integer  "VAMedicalServices"
    t.integer  "NoVAMedReason"
    t.integer  "EmployerProvided"
    t.integer  "NoEmployerProvidedReason"
    t.integer  "COBRA"
    t.integer  "NoCOBRAReason"
    t.integer  "PrivatePay"
    t.integer  "NoPrivatePayReason"
    t.integer  "StateHealthIns"
    t.integer  "NoStateHealthInsReason"
    t.integer  "HIVAIDSAssistance"
    t.integer  "NoHIVAIDSAssistanceReason"
    t.integer  "ADAP"
    t.integer  "NoADAPReason"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",                     limit: 4000
    t.integer  "data_source_id"
    t.integer  "IndianHealthServices"
    t.integer  "NoIndianHealthServicesReason"
    t.integer  "OtherInsurance"
    t.string   "OtherInsuranceIdentify",       limit: 50
  end

  add_index "IncomeBenefits", ["DateCreated"], name: "income_benefits_date_created", using: :btree
  add_index "IncomeBenefits", ["DateUpdated"], name: "income_benefits_date_updated", using: :btree
  add_index "IncomeBenefits", ["ExportID"], name: "income_benefits_export_id", using: :btree
  add_index "IncomeBenefits", ["PersonalID"], name: "index_IncomeBenefits_on_PersonalID", using: :btree
  add_index "IncomeBenefits", ["data_source_id", "IncomeBenefitsID"], name: "unk_IncomeBenefits", unique: true, using: :btree
  add_index "IncomeBenefits", ["data_source_id", "PersonalID"], name: "index_IncomeBenefits_on_data_source_id_and_PersonalID", using: :btree

  create_table "Inventory", force: :cascade do |t|
    t.string   "InventoryID",           limit: 4000
    t.string   "ProjectID",             limit: 4000
    t.string   "CoCCode",               limit: 50
    t.date     "InformationDate"
    t.integer  "HouseholdType"
    t.integer  "BedType"
    t.integer  "Availability"
    t.integer  "UnitInventory"
    t.integer  "BedInventory"
    t.integer  "CHBedInventory"
    t.integer  "VetBedInventory"
    t.integer  "YouthBedInventory"
    t.integer  "YouthAgeGroup"
    t.date     "InventoryStartDate"
    t.date     "InventoryEndDate"
    t.integer  "HMISParticipatingBeds"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",              limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Inventory", ["DateCreated"], name: "inventory_date_created", using: :btree
  add_index "Inventory", ["DateUpdated"], name: "inventory_date_updated", using: :btree
  add_index "Inventory", ["ExportID"], name: "inventory_export_id", using: :btree
  add_index "Inventory", ["ProjectID"], name: "index_Inventory_on_ProjectID", using: :btree
  add_index "Inventory", ["data_source_id", "InventoryID"], name: "unk_Inventory", unique: true, using: :btree

  create_table "Organization", force: :cascade do |t|
    t.string   "OrganizationID",         limit: 4000
    t.string   "OrganizationName",       limit: 4000
    t.string   "OrganizationCommonName", limit: 4000
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",               limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Organization", ["ExportID"], name: "organization_export_id", using: :btree
  add_index "Organization", ["data_source_id", "OrganizationID"], name: "unk_Organization", unique: true, using: :btree

  create_table "Project", force: :cascade do |t|
    t.string   "ProjectID",              limit: 4000
    t.string   "OrganizationID",         limit: 4000
    t.string   "ProjectName",            limit: 4000
    t.string   "ProjectCommonName",      limit: 4000
    t.integer  "ContinuumProject"
    t.integer  "ProjectType"
    t.integer  "ResidentialAffiliation"
    t.integer  "TrackingMethod"
    t.integer  "TargetPopulation"
    t.integer  "PITCount"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",               limit: 4000
    t.integer  "data_source_id"
    t.integer  "act_as_project_type"
  end

  add_index "Project", ["DateCreated"], name: "project_date_created", using: :btree
  add_index "Project", ["DateUpdated"], name: "project_date_updated", using: :btree
  add_index "Project", ["ExportID"], name: "project_export_id", using: :btree
  add_index "Project", ["ProjectID"], name: "index_Project_on_ProjectID", using: :btree
  add_index "Project", ["ProjectType"], name: "index_Project_on_ProjectType", using: :btree
  add_index "Project", ["data_source_id", "ProjectID"], name: "unk_Project", unique: true, using: :btree

  create_table "ProjectCoC", force: :cascade do |t|
    t.string   "ProjectCoCID",   limit: 50
    t.string   "ProjectID",      limit: 4000
    t.string   "CoCCode",        limit: 50
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",       limit: 4000
    t.integer  "data_source_id"
  end

  add_index "ProjectCoC", ["DateCreated"], name: "project_coc_date_created", using: :btree
  add_index "ProjectCoC", ["DateUpdated"], name: "project_coc_date_updated", using: :btree
  add_index "ProjectCoC", ["ExportID"], name: "project_coc_export_id", using: :btree
  add_index "ProjectCoC", ["data_source_id", "ProjectCoCID"], name: "unk_ProjectCoC", unique: true, using: :btree

  create_table "Services", force: :cascade do |t|
    t.string   "ServicesID",        limit: 4000
    t.string   "ProjectEntryID",    limit: 4000
    t.string   "PersonalID",        limit: 4000
    t.date     "DateProvided"
    t.integer  "RecordType"
    t.integer  "TypeProvided"
    t.string   "OtherTypeProvided", limit: 4000
    t.integer  "SubTypeProvided"
    t.decimal  "FAAmount",                       precision: 18
    t.integer  "ReferralOutcome"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",            limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",          limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Services", ["DateCreated"], name: "services_date_created", using: :btree
  add_index "Services", ["DateDeleted"], name: "index_Services_on_DateDeleted", using: :btree
  add_index "Services", ["DateUpdated"], name: "services_date_updated", using: :btree
  add_index "Services", ["ExportID"], name: "services_export_id", using: :btree
  add_index "Services", ["PersonalID"], name: "index_Services_on_PersonalID", using: :btree
  add_index "Services", ["data_source_id", "PersonalID"], name: "index_Services_on_data_source_id_and_PersonalID", using: :btree
  add_index "Services", ["data_source_id", "ServicesID"], name: "unk_Services", unique: true, using: :btree

  create_table "Site", force: :cascade do |t|
    t.string   "SiteID",         limit: 4000
    t.string   "ProjectID",      limit: 4000
    t.string   "CoCCode",        limit: 50
    t.integer  "PrincipalSite"
    t.string   "Geocode",        limit: 50
    t.string   "Address",        limit: 4000
    t.string   "City",           limit: 4000
    t.string   "State",          limit: 2
    t.string   "ZIP",            limit: 10
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID",       limit: 4000
    t.integer  "data_source_id"
  end

  add_index "Site", ["DateCreated"], name: "site_date_created", using: :btree
  add_index "Site", ["DateUpdated"], name: "site_date_updated", using: :btree
  add_index "Site", ["ExportID"], name: "site_export_id", using: :btree

  create_table "client_service_history", id: false, force: :cascade do |t|
    t.integer "unduplicated_client_id"
    t.date    "date"
    t.date    "first_date_in_program"
    t.date    "last_date_in_program"
    t.string  "program_group_id"
    t.integer "program_type"
    t.integer "program_id"
    t.integer "age"
    t.decimal "income"
    t.integer "income_type"
    t.integer "income_source_code"
    t.integer "destination"
    t.string  "head_of_household_id"
    t.string  "household_id"
    t.string  "database_id"
    t.string  "program_name"
    t.integer "program_tracking_method"
    t.string  "record_type"
    t.integer "dc_id"
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
  end

  create_table "clients_unduplicated", force: :cascade do |t|
    t.string  "client_unique_id",       null: false
    t.integer "unduplicated_client_id", null: false
    t.integer "dc_id"
  end

  add_index "clients_unduplicated", ["unduplicated_client_id"], name: "unduplicated_clients_unduplicated_client_id", using: :btree

  create_table "data_sources", force: :cascade do |t|
    t.string   "name",               limit: 4000
    t.string   "file_path",          limit: 4000
    t.datetime "last_imported_at"
    t.date     "newest_updated_at"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "source_type",        limit: 4000
    t.boolean  "munged_personal_id",              default: false, null: false
    t.string   "short_name",         limit: 4000
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "import_logs", force: :cascade do |t|
    t.integer  "data_source_id"
    t.string   "files",          limit: 4000
    t.text     "import_errors"
    t.string   "summary",        limit: 4000
    t.datetime "completed_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "zip",            limit: 4000
  end

  add_index "import_logs", ["completed_at"], name: "index_import_logs_on_completed_at", using: :btree
  add_index "import_logs", ["created_at"], name: "index_import_logs_on_created_at", using: :btree
  add_index "import_logs", ["data_source_id"], name: "index_import_logs_on_data_source_id", using: :btree
  add_index "import_logs", ["updated_at"], name: "index_import_logs_on_updated_at", using: :btree

  create_table "imports", force: :cascade do |t|
    t.string   "file"
    t.string   "source"
    t.float    "percent_complete"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.json     "unzipped_files"
    t.json     "import_errors"
  end

  add_index "imports", ["deleted_at"], name: "index_imports_on_deleted_at", using: :btree

  create_table "nicknames", force: :cascade do |t|
    t.string  "name"
    t.integer "nickname_id"
  end

  create_table "report_results", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "import_id"
    t.float    "percent_complete"
    t.json     "results"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "deleted_at"
    t.datetime "completed_at"
    t.integer  "user_id"
    t.json     "original_results"
    t.json     "options"
  end

  add_index "report_results", ["deleted_at"], name: "index_report_results_on_deleted_at", using: :btree
  add_index "report_results", ["report_id"], name: "index_report_results_on_report_id", using: :btree

  create_table "report_results_summaries", force: :cascade do |t|
    t.string   "name",                   null: false
    t.string   "type",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "weight",     default: 0, null: false
  end

  create_table "reports", force: :cascade do |t|
    t.string   "name",                                  null: false
    t.string   "type",                                  null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "weight",                    default: 0, null: false
    t.integer  "report_results_summary_id"
  end

  add_index "reports", ["report_results_summary_id"], name: "index_reports_on_report_results_summary_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.string   "verb"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "can_view_clients",        default: false
    t.boolean  "can_edit_clients",        default: false
    t.boolean  "can_view_reports",        default: false
    t.boolean  "can_edit_users",          default: false
    t.boolean  "can_view_full_ssn",       default: false
    t.boolean  "can_view_full_dob",       default: false
    t.boolean  "can_view_imports",        default: false
    t.boolean  "can_edit_roles",          default: false
    t.boolean  "can_view_censuses",       default: false
    t.boolean  "can_view_census_details", default: false
    t.boolean  "can_view_projects",       default: false
    t.boolean  "can_view_organizations",  default: false
  end

  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "similarity_metrics", force: :cascade do |t|
    t.string   "type",                             null: false
    t.float    "mean",               default: 0.0, null: false
    t.float    "standard_deviation", default: 0.0, null: false
    t.float    "weight",             default: 1.0, null: false
    t.integer  "n",                  default: 0,   null: false
    t.hstore   "other_state",        default: {},  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "similarity_metrics", ["type"], name: "index_similarity_metrics_on_type", unique: true, using: :btree

  create_table "unique_names", force: :cascade do |t|
    t.string "name"
    t.string "double_metaphone"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_roles", ["role_id"], name: "index_user_roles_on_role_id", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "last_name",                           null: false
    t.string   "email",                               null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.datetime "deleted_at"
    t.string   "first_name"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      default: 0
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "session_id"
    t.string   "request_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "warehouse_client_service_history", force: :cascade do |t|
    t.integer "client_id",                           null: false
    t.integer "data_source_id"
    t.date    "date",                                null: false
    t.date    "first_date_in_program",               null: false
    t.date    "last_date_in_program"
    t.string  "enrollment_group_id",     limit: 50
    t.integer "age"
    t.integer "destination"
    t.string  "head_of_household_id",    limit: 50
    t.string  "household_id",            limit: 50
    t.string  "project_id",              limit: 50
    t.string  "project_name",            limit: 150
    t.integer "project_type"
    t.integer "project_tracking_method"
    t.string  "organization_id",         limit: 50
    t.string  "record_type",             limit: 50
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type"
  end

  add_index "warehouse_client_service_history", ["client_id"], name: "index_warehouse_client_service_history_on_client_id", using: :btree
  add_index "warehouse_client_service_history", ["data_source_id", "organization_id", "project_id", "record_type"], name: "index_w_c_s_h_on_data_s_id_and_o_id_and_p_id_and_r_type", using: :btree
  add_index "warehouse_client_service_history", ["data_source_id"], name: "index_warehouse_client_service_history_on_data_source_id", using: :btree
  add_index "warehouse_client_service_history", ["date", "data_source_id", "organization_id", "project_id", "project_type"], name: "index_w_c_s_h_on_date_and_data_s_id_and_o_id_and_p_id_and_p_typ", using: :btree
  add_index "warehouse_client_service_history", ["first_date_in_program"], name: "index_warehouse_client_service_history_on_first_date_in_program", using: :btree
  add_index "warehouse_client_service_history", ["household_id"], name: "index_warehouse_client_service_history_on_household_id", using: :btree
  add_index "warehouse_client_service_history", ["last_date_in_program"], name: "index_warehouse_client_service_history_on_last_date_in_program", using: :btree
  add_index "warehouse_client_service_history", ["project_tracking_method"], name: "index_w_c_s_h_on_p_t_m", using: :btree
  add_index "warehouse_client_service_history", ["project_type"], name: "index_warehouse_client_service_history_on_project_type", using: :btree
  add_index "warehouse_client_service_history", ["record_type"], name: "index_warehouse_client_service_history_on_record_type", using: :btree

  add_foreign_key "report_results", "users"
  add_foreign_key "reports", "report_results_summaries"
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
end

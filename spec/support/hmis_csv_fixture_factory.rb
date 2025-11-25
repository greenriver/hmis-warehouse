###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'fileutils'

# Factory for programmatically building HMIS CSV fixture bundles.
# Generates a temp directory with Export.csv, Organization.csv, Project.csv,
# ProjectCoC.csv, User.csv, Client.csv, Enrollment.csv, and optional custom files.
#
# Usage:
#   factory = HmisCsvFixtureFactory.new
#   factory.export_start_date = Date.new(2024, 1, 1)
#   factory.export_end_date = Date.new(2024, 3, 31)
#   factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'User')
#   factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
#   factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-1', personal_id: 'client-1', sexual_orientation: 1)
#   path = factory.create!
#   # use path with import_hmis_csv_fixture
#   factory.cleanup!
#
class HmisCsvFixtureFactory
  attr_accessor :export_id, :export_start_date, :export_end_date, :export_date
  attr_accessor :organization_id, :organization_name
  attr_accessor :project_id, :project_name, :project_type, :coc_code

  def initialize
    @export_id = SecureRandom.hex(16)
    @export_start_date = Date.new(2024, 1, 1)
    @export_end_date = Date.new(2024, 3, 31)
    @export_date = Time.current
    @organization_id = 'org-1'
    @organization_name = 'Test Organization'
    @project_id = 'project-1'
    @project_name = 'Test Project'
    @project_type = 1 # Emergency Shelter
    @coc_code = 'XX-500'

    @clients = []
    @enrollments = []
    @custom_enrollment_augmentations = []
    @custom_gender_augmentations = []
    @tmp_dir = nil
  end

  def add_client(personal_id:, first_name: 'Test', last_name: 'Client', dob: Date.new(1990, 1, 1), **attrs)
    @clients << {
      personal_id: personal_id,
      first_name: first_name,
      last_name: last_name,
      dob: dob,
    }.merge(attrs)
  end

  def add_enrollment(enrollment_id:, personal_id:, entry_date:, project_id: nil, household_id: nil, **attrs)
    @enrollments << {
      enrollment_id: enrollment_id,
      personal_id: personal_id,
      project_id: project_id || @project_id,
      entry_date: entry_date,
      household_id: household_id || "hh-#{enrollment_id}",
    }.merge(attrs)
  end

  def add_custom_enrollment_augmentation(enrollment_id:, personal_id:, sexual_orientation: nil, translation_needed: nil, preferred_language: nil, **attrs)
    @custom_enrollment_augmentations << {
      enrollment_id: enrollment_id,
      personal_id: personal_id,
      sexual_orientation: sexual_orientation,
      translation_needed: translation_needed,
      preferred_language: preferred_language,
    }.merge(attrs)
  end

  def add_custom_gender_augmentation(personal_id:, woman: nil, man: nil, non_binary: nil, **attrs)
    @custom_gender_augmentations << {
      personal_id: personal_id,
      woman: woman,
      man: man,
      non_binary: non_binary,
    }.merge(attrs)
  end

  # Build the fixture directory and return the path (parent of 'source')
  def create!
    @tmp_dir = Dir.mktmpdir('hmis_csv_fixture')
    source_dir = File.join(@tmp_dir, 'source')
    FileUtils.mkdir_p(source_dir)

    write_export_csv(source_dir)
    write_organization_csv(source_dir)
    write_project_csv(source_dir)
    write_project_coc_csv(source_dir)
    write_user_csv(source_dir)
    write_client_csv(source_dir)
    write_enrollment_csv(source_dir)
    write_empty_files(source_dir)

    write_custom_enrollment_augmentation_csv(source_dir) if @custom_enrollment_augmentations.any?
    write_custom_gender_csv(source_dir) if @custom_gender_augmentations.any?

    @tmp_dir
  end

  def cleanup!
    FileUtils.rm_rf(@tmp_dir) if @tmp_dir && Dir.exist?(@tmp_dir)
    @tmp_dir = nil
  end

  private

  def timestamp
    @timestamp ||= Time.current.strftime('%Y-%m-%d %H:%M:%S')
  end

  def write_export_csv(dir)
    row = {
      'ExportID' => @export_id,
      'SourceType' => 3,
      'SourceID' => '',
      'SourceName' => 'Test Warehouse',
      'SourceContactFirst' => 'Automated',
      'SourceContactLast' => 'Export',
      'SourceContactPhone' => '',
      'SourceContactExtension' => '',
      'SourceContactEmail' => '',
      'ExportDate' => @export_date.strftime('%Y-%m-%d %H:%M:%S'),
      'ExportStartDate' => @export_start_date.strftime('%Y-%m-%d'),
      'ExportEndDate' => @export_end_date.strftime('%Y-%m-%d'),
      'SoftwareName' => 'Test HMIS',
      'SoftwareVersion' => '1',
      'CSVVersion' => '2026 v1.0',
      'ExportPeriodType' => 3,
      'ExportDirective' => 3,
      'HashStatus' => 1,
      'ImplementationID' => 'Test Warehouse',
    }
    write_csv_from_hashes(dir, 'Export.csv', [row])
  end

  def write_organization_csv(dir)
    row = {
      'OrganizationID' => @organization_id,
      'OrganizationName' => @organization_name,
      'VictimServiceProvider' => '',
      'OrganizationCommonName' => '',
      'DateCreated' => timestamp,
      'DateUpdated' => timestamp,
      'UserID' => 'user-1',
      'DateDeleted' => '',
      'ExportID' => @export_id,
    }
    write_csv_from_hashes(dir, 'Organization.csv', [row])
  end

  def write_project_csv(dir)
    row = {
      'ProjectID' => @project_id,
      'OrganizationID' => @organization_id,
      'ProjectName' => @project_name,
      'ProjectCommonName' => '',
      'OperatingStartDate' => '',
      'OperatingEndDate' => '',
      'ContinuumProject' => 0,
      'ProjectType' => @project_type,
      'HousingType' => '',
      'RRHSubType' => '',
      'ResidentialAffiliation' => '',
      'TargetPopulation' => 4,
      'HOPWAMedAssistedLivingFac' => '',
      'PITCount' => '',
      'DateCreated' => timestamp,
      'DateUpdated' => timestamp,
      'UserID' => 'user-1',
      'DateDeleted' => '',
      'ExportID' => @export_id,
    }
    write_csv_from_hashes(dir, 'Project.csv', [row])
  end

  def write_project_coc_csv(dir)
    row = {
      'ProjectCoCID' => "coc-#{@project_id}",
      'ProjectID' => @project_id,
      'CoCCode' => @coc_code,
      'Geocode' => '',
      'Address1' => '',
      'Address2' => '',
      'City' => '',
      'State' => '',
      'Zip' => '',
      'GeographyType' => '',
      'DateCreated' => timestamp,
      'DateUpdated' => timestamp,
      'UserID' => 'user-1',
      'DateDeleted' => '',
      'ExportID' => @export_id,
    }
    write_csv_from_hashes(dir, 'ProjectCoC.csv', [row])
  end

  def write_user_csv(dir)
    row = {
      'UserID' => 'user-1',
      'UserFirstName' => 'Test',
      'UserLastName' => 'User',
      'UserPhone' => '',
      'UserExtension' => '',
      'UserEmail' => 'test@example.com',
      'DateCreated' => timestamp,
      'DateUpdated' => timestamp,
      'DateDeleted' => '',
      'ExportID' => @export_id,
    }
    write_csv_from_hashes(dir, 'User.csv', [row])
  end

  def write_client_csv(dir)
    rows = @clients.map do |c|
      {
        'PersonalID' => c[:personal_id],
        'FirstName' => c[:first_name],
        'MiddleName' => '',
        'LastName' => c[:last_name],
        'NameSuffix' => '',
        'NameDataQuality' => '',
        'SSN' => '',
        'SSNDataQuality' => 99,
        'DOB' => c[:dob].strftime('%Y-%m-%d'),
        'DOBDataQuality' => 99,
        'Sex' => '',
        'AmIndAKNative' => 0,
        'Asian' => 0,
        'BlackAfAmerican' => 0,
        'HispanicLatinao' => 0,
        'MidEastNAfrican' => 0,
        'NativeHIPacific' => 0,
        'White' => 0,
        'RaceNone' => 99,
        'AdditionalRaceEthnicity' => '',
        'VeteranStatus' => 99,
        'YearEnteredService' => '',
        'YearSeparated' => '',
        'WorldWarII' => '',
        'KoreanWar' => '',
        'VietnamWar' => '',
        'DesertStorm' => '',
        'AfghanistanOEF' => '',
        'IraqOIF' => '',
        'IraqOND' => '',
        'OtherTheater' => '',
        'MilitaryBranch' => '',
        'DischargeStatus' => '',
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'DateDeleted' => '',
        'ExportID' => @export_id,
      }
    end
    write_csv_from_hashes(dir, 'Client.csv', rows)
  end

  def write_enrollment_csv(dir)
    rows = @enrollments.map do |e|
      {
        'EnrollmentID' => e[:enrollment_id],
        'PersonalID' => e[:personal_id],
        'ProjectID' => e[:project_id],
        'EntryDate' => e[:entry_date].strftime('%Y-%m-%d'),
        'HouseholdID' => e[:household_id],
        'RelationshipToHoH' => 1,
        'EnrollmentCoC' => @coc_code,
        'LivingSituation' => 116,
        'RentalSubsidyType' => '',
        'LengthOfStay' => '',
        'LOSUnderThreshold' => '',
        'PreviousStreetESSH' => '',
        'DateToStreetESSH' => '',
        'TimesHomelessPastThreeYears' => '',
        'MonthsHomelessPastThreeYears' => '',
        'DisablingCondition' => 99,
        'DateOfEngagement' => '',
        'MoveInDate' => '',
        'DateOfPATHStatus' => '',
        'ClientEnrolledInPATH' => '',
        'ReasonNotEnrolled' => '',
        'PercentAMI' => '',
        'ReferralSource' => '',
        'CountOutreachReferralApproaches' => '',
        'DateOfBCPStatus' => '',
        'EligibleForRHY' => '',
        'ReasonNoServices' => '',
        'RunawayYouth' => '',
        'FormerWardChildWelfare' => '',
        'ChildWelfareYears' => '',
        'ChildWelfareMonths' => '',
        'FormerWardJuvenileJustice' => '',
        'JuvenileJusticeYears' => '',
        'JuvenileJusticeMonths' => '',
        'UnemploymentFam' => '',
        'MentalHealthDisorderFam' => '',
        'PhysicalDisabilityFam' => '',
        'AlcoholDrugUseDisorderFam' => '',
        'InsufficientIncome' => '',
        'IncarceratedParent' => '',
        'VAMCStation' => '',
        'TargetScreenReqd' => '',
        'TimeToHousingLoss' => '',
        'AnnualPercentAMI' => '',
        'LiteralHomelessHistory' => '',
        'ClientLeaseholder' => '',
        'HOHLeaseholder' => '',
        'SubsidyAtRisk' => '',
        'EvictionHistory' => '',
        'CriminalRecord' => '',
        'IncarceratedAdult' => '',
        'PrisonDischarge' => '',
        'SexOffender' => '',
        'DisabledHoH' => '',
        'CurrentPregnant' => '',
        'SingleParent' => '',
        'DependentUnder6' => '',
        'HH5Plus' => '',
        'CoCPrioritized' => '',
        'HPScreeningScore' => '',
        'ThresholdScore' => '',
        'MentalHealthConsultation' => '',
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'DateDeleted' => '',
        'ExportID' => @export_id,
      }
    end
    write_csv_from_hashes(dir, 'Enrollment.csv', rows)
  end

  def write_custom_enrollment_augmentation_csv(dir)
    rows = @custom_enrollment_augmentations.map do |a|
      {
        'EnrollmentID' => a[:enrollment_id],
        'PersonalID' => a[:personal_id],
        'SexualOrientation' => a[:sexual_orientation] || '',
        'SexualOrientationOther' => a[:sexual_orientation_other] || '',
        'TranslationNeeded' => a[:translation_needed] || '',
        'PreferredLanguage' => a[:preferred_language] || '',
        'PreferredLanguageDifferent' => a[:preferred_language_different] || '',
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'DateDeleted' => '',
        'ExportID' => @export_id,
      }
    end
    write_csv_from_hashes(dir, 'CustomEnrollmentFY26Deprecations.csv', rows)
  end

  def write_custom_gender_csv(dir)
    rows = @custom_gender_augmentations.map do |a|
      {
        'PersonalID' => a[:personal_id],
        'Woman' => a[:woman] || '',
        'Man' => a[:man] || '',
        'NonBinary' => a[:non_binary] || '',
        'CulturallySpecific' => a[:culturally_specific] || '',
        'Transgender' => a[:transgender] || '',
        'Questioning' => a[:questioning] || '',
        'DifferentIdentity' => a[:different_identity] || '',
        'GenderNone' => a[:gender_none] || '',
        'DifferentIdentityText' => a[:different_identity_text] || '',
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'DateDeleted' => '',
        'ExportID' => @export_id,
      }
    end
    write_csv_from_hashes(dir, 'CustomGender.csv', rows)
  end

  # Write empty placeholder files for required HUD tables we don't populate
  def write_empty_files(dir)
    empty_files = [
      'Affiliation.csv', 'Assessment.csv', 'AssessmentQuestions.csv', 'AssessmentResults.csv', 'CEParticipation.csv', 'CurrentLivingSituation.csv', 'EmploymentEducation.csv', 'Event.csv', 'Exit.csv', 'Funder.csv', 'HMISParticipation.csv', 'Inventory.csv', 'Services.csv', 'YouthEducationStatus.csv'
    ]
    empty_files.each do |filename|
      # Write just headers for these files
      write_empty_hud_file(dir, filename)
    end
  end

  def write_empty_hud_file(dir, filename)
    # Minimal headers for empty HUD files
    headers_map = {
      'Affiliation.csv' => ['AffiliationID', 'ProjectID', 'ResProjectID', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Assessment.csv' => ['AssessmentID', 'EnrollmentID', 'PersonalID', 'AssessmentDate', 'AssessmentLocation', 'AssessmentType', 'AssessmentLevel', 'PrioritizationStatus', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'AssessmentQuestions.csv' => ['AssessmentQuestionID', 'AssessmentID', 'EnrollmentID', 'PersonalID', 'AssessmentQuestionGroup', 'AssessmentQuestionOrder', 'AssessmentQuestion', 'AssessmentAnswer', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'AssessmentResults.csv' => ['AssessmentResultID', 'AssessmentID', 'EnrollmentID', 'PersonalID', 'AssessmentResultType', 'AssessmentResult', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'CEParticipation.csv' => ['CEParticipationID', 'ProjectID', 'AccessPoint', 'PreventionAssessment', 'CrisisAssessment', 'HousingAssessment', 'DirectServices', 'ReceivesReferrals', 'CEParticipationStatusStartDate', 'CEParticipationStatusEndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'CurrentLivingSituation.csv' => ['CurrentLivingSitID', 'EnrollmentID', 'PersonalID', 'InformationDate', 'CurrentLivingSituation', 'CLSSubsidyType', 'VerifiedBy', 'LeaveSituation14Days', 'SubsequentResidence', 'ResourcesToObtain', 'LeaseOwn60Day', 'MovedTwoOrMore', 'LocationDetails', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'EmploymentEducation.csv' => ['EmploymentEducationID', 'EnrollmentID', 'PersonalID', 'InformationDate', 'LastGradeCompleted', 'SchoolStatus', 'Employed', 'EmploymentType', 'NotEmployedReason', 'DataCollectionStage', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Event.csv' => ['EventID', 'EnrollmentID', 'PersonalID', 'EventDate', 'Event', 'ProbSolDivRRResult', 'ReferralCaseManageAfter', 'LocationCrisisorPHHousing', 'ReferralResult', 'ResultDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Exit.csv' => ['ExitID', 'EnrollmentID', 'PersonalID', 'ExitDate', 'Destination', 'OtherDestination', 'HousingAssessment', 'SubsidyInformation', 'ProjectCompletionStatus', 'EarlyExitReason', 'ExchangeForSex', 'ExchangeForSexPastThreeMonths', 'CountOfExchangeForSex', 'AskedOrForcedToExchangeForSex', 'AskedOrForcedToExchangeForSexPastThreeMonths', 'WorkplaceViolenceThreats', 'WorkplacePromiseDifference', 'CoercedToContinueWork', 'LaborExploitPastThreeMonths', 'CounselingReceived', 'IndividualCounseling', 'FamilyCounseling', 'GroupCounseling', 'SessionCountAtExit', 'PostExitCounselingPlan', 'SessionsInPlan', 'DestinationSafeClient', 'DestinationSafeWorker', 'PosAdultConnections', 'PosPeerConnections', 'PosCommunityConnections', 'AftercareDate', 'AftercareProvided', 'EmailSocialMedia', 'Telephone', 'InPersonIndividual', 'InPersonGroup', 'CMExitReason', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Funder.csv' => ['FunderID', 'ProjectID', 'Funder', 'OtherFunder', 'GrantID', 'StartDate', 'EndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'HMISParticipation.csv' => ['HMISParticipationID', 'ProjectID', 'HMISParticipationType', 'HMISParticipationStatusStartDate', 'HMISParticipationStatusEndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Inventory.csv' => ['InventoryID', 'ProjectID', 'CoCCode', 'HouseholdType', 'Availability', 'UnitInventory', 'BedInventory', 'CHVetBedInventory', 'YouthVetBedInventory', 'VetBedInventory', 'CHYouthBedInventory', 'YouthBedInventory', 'CHBedInventory', 'OtherBedInventory', 'ESBedType', 'InventoryStartDate', 'InventoryEndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'Services.csv' => ['ServicesID', 'EnrollmentID', 'PersonalID', 'DateProvided', 'RecordType', 'TypeProvided', 'OtherTypeProvided', 'SubTypeProvided', 'FAAmount', 'ReferralOutcome', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
      'YouthEducationStatus.csv' => ['YouthEducationStatusID', 'EnrollmentID', 'PersonalID', 'InformationDate', 'CurrentSchoolAttend', 'MostRecentEdStatus', 'CurrentEdStatus', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
    }
    headers = headers_map[filename] || ['ID']
    write_csv(dir, filename, headers, [])
  end

  def write_csv_from_hashes(dir, filename, rows_of_hashes)
    return if rows_of_hashes.empty?

    path = File.join(dir, filename)
    headers = rows_of_hashes.first.keys

    CSV.open(path, 'wb') do |csv|
      csv << headers
      rows_of_hashes.each do |row|
        csv << row.values_at(*headers)
      end
    end
  end

  def write_csv(dir, filename, headers, rows)
    path = File.join(dir, filename)
    CSV.open(path, 'wb') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end
end

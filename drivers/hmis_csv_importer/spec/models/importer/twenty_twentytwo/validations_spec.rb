###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Validate import files', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::WhitelistedProjectsForClients.create(ProjectID: 'ALLOW', data_source_id: data_source.id)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/validation_files',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end

  # Affiliations
  it 'includes expected affiliations' do
    expect(GrdaWarehouse::Hud::Affiliation.count).to eq(2)
  end

  it 'includes expected affiliations failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Affiliation'").count).to eq(2)
  end

  it 'excludes expected affiliations failures' do
    expect(GrdaWarehouse::Hud::Affiliation.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # Assessments
  it 'includes expected assessments' do
    expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
  end

  it 'includes expected assessments failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Assessment'").count).to eq(6)
  end

  it 'includes expected assessments validations' do
    expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Assessment'").count).to eq(3)
    # Line 5 also would also raise 3 validation errors but its filtered out in the loader
    # expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Assessment'").count).to eq(6)
  end

  it 'excludes expected assessments failures' do
    expect(GrdaWarehouse::Hud::Assessment.where(AssessmentID: 'FAILURE').count).to eq(0)
  end

  # AssessmentQuestions
  it 'includes expected assessment questions' do
    expect(GrdaWarehouse::Hud::AssessmentQuestion.count).to eq(2)
  end

  it 'includes expected assessment questions failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%AssessmentQuestion'").count).to eq(3)
  end

  it 'excludes expected assessment questions validations' do
    expect(GrdaWarehouse::Hud::AssessmentQuestion.where(AssessmentQuestionID: 'FAILURE').count).to eq(0)
  end

  # AssessmentResults
  it 'includes expected assessment questions' do
    expect(GrdaWarehouse::Hud::AssessmentResult.count).to eq(2)
  end

  it 'includes expected assessment questions failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%AssessmentResult'").count).to eq(3)
  end

  it 'excludes expected assessment questions failures' do
    expect(GrdaWarehouse::Hud::AssessmentResult.where(AssessmentResultID: 'FAILURE').count).to eq(0)
  end

  # Client
  it 'includes expected clients' do
    # NOTE: it is extremely difficult for a client record to fail to import
    expect(GrdaWarehouse::Hud::Client.source.count).to eq(4)
  end

  it 'includes expected client validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Client'").count).to eq(4)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Client'").count).to eq(1)
    end
  end

  it 'excludes expected client failures' do
    expect(GrdaWarehouse::Hud::Client.where(PersonalID: 'FAILURE').count).to eq(1)
  end

  # CurrentLivingSituations
  it 'includes expected current_living_situation' do
    expect(GrdaWarehouse::Hud::CurrentLivingSituation.count).to eq(2)
  end

  it 'includes expected current_living_situation failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%CurrentLivingSituation'").count).to eq(5)
  end

  it 'excludes expected current_living_situation failures' do
    expect(GrdaWarehouse::Hud::CurrentLivingSituation.where(CurrentLivingSitID: 'VALID').count).to eq(1)
  end

  # Disability
  it 'includes expected disabilities' do
    expect(GrdaWarehouse::Hud::Disability.count).to eq(2)
  end

  it 'includes expected disabilities failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Disability'").count).to eq(4)
  end

  it 'includes expected disabilities validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Disability'").count).to eq(6)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Disability'").count).to eq(1)
    end
  end

  it 'excludes expected disabilities failures' do
    expect(GrdaWarehouse::Hud::Disability.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # EmploymentEducation
  it 'includes expected employment educations' do
    expect(GrdaWarehouse::Hud::EmploymentEducation.count).to eq(2)
  end

  it 'includes expected employment educations failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%EmploymentEducation'").count).to eq(2)
  end

  it 'includes expected employment educations validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%EmploymentEducation'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%EmploymentEducation'").count).to eq(2)
    end
  end

  it 'excludes expected employment educations failures' do
    expect(GrdaWarehouse::Hud::EmploymentEducation.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Enrollment
  it 'includes expected enrollments' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
  end

  it 'includes expected enrollments failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Enrollment'").count).to eq(3)
  end

  it 'includes expected enrollments validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Enrollment'").count).to eq(4)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Enrollment'").count).to eq(2)
    end
  end

  it 'excludes expected enrollments failures' do
    expect(GrdaWarehouse::Hud::Enrollment.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  it 'has two entry after exit validation errors' do
    expect(HmisCsvImporter::HmisCsvValidation::EntryAfterExit.count).to eq(2)
  end

  # Exit
  it 'includes expected exits' do
    expect(GrdaWarehouse::Hud::Exit.count).to eq(4)
  end

  it 'includes expected exits failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Exit'").count).to eq(2)
  end

  it 'includes expected exits validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Exit'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%:Exit'").count).to eq(2)
    end
  end

  it 'excludes expected exits failures' do
    expect(GrdaWarehouse::Hud::Exit.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # EnrollmentCoc
  it 'includes expected enrollment_cocs' do
    expect(GrdaWarehouse::Hud::EnrollmentCoc.count).to eq(2)
  end

  it 'includes expected enrollment_cocs failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%EnrollmentCoc'").count).to eq(3)
  end

  it 'includes expected enrollment_cocs validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%EnrollmentCoc'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%EnrollmentCoc'").count).to eq(2)
    end
  end

  it 'excludes expected enrollment_cocs failures' do
    expect(GrdaWarehouse::Hud::EnrollmentCoc.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Event
  it 'includes expected events' do
    expect(GrdaWarehouse::Hud::Event.count).to eq(2)
  end

  it 'includes expected events failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Event'").count).to eq(4)
  end

  it 'includes expected events validations' do
    expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Event'").count).to eq(1)
  end

  it 'excludes expected events failures' do
    expect(GrdaWarehouse::Hud::Event.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Export
  it 'does not include any Export errors' do
    expect(HmisCsvImporter::HmisCsvValidation::Base.where("source_type LIKE '%Export'").count).to eq(0)
  end

  # Funder
  it 'includes expected funders' do
    expect(GrdaWarehouse::Hud::Funder.count).to eq(2)
  end

  it 'includes expected funders failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Funder'").count).to eq(1)
  end

  it 'includes expected funders validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Funder'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Funder'").count).to eq(2)
    end
  end

  it 'excludes expected funders failures' do
    expect(GrdaWarehouse::Hud::Funder.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # HealthAndDv
  it 'includes expected health_and_dvs' do
    expect(GrdaWarehouse::Hud::HealthAndDv.count).to eq(2)
  end

  it 'includes expected health_and_dvs failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%HealthAndDv'").count).to eq(2)
  end

  it 'includes expected health_and_dvs validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%HealthAndDv'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%HealthAndDv'").count).to eq(1)
    end
  end

  it 'excludes expected health_and_dvs failures' do
    expect(GrdaWarehouse::Hud::HealthAndDv.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # IncomeBenefit
  it 'includes expected income_benefits' do
    expect(GrdaWarehouse::Hud::IncomeBenefit.count).to eq(2)
  end

  it 'includes expected income_benefits failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%IncomeBenefit'").count).to eq(2)
  end

  it 'includes expected income_benefits validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%IncomeBenefit'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%IncomeBenefit'").count).to eq(1)
    end
  end

  it 'excludes expected income_benefits failures' do
    expect(GrdaWarehouse::Hud::IncomeBenefit.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Inventory
  it 'includes expected inventory' do
    expect(GrdaWarehouse::Hud::Inventory.count).to eq(2)
  end

  it 'includes expected inventory failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Inventory'").count).to eq(1)
  end

  it 'includes expected inventory validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Inventory'").count).to eq(2)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Inventory'").count).to eq(5)
    end
  end

  it 'excludes expected inventory failures' do
    expect(GrdaWarehouse::Hud::Inventory.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # Organization
  it 'includes expected organizations' do
    expect(GrdaWarehouse::Hud::Organization.count).to eq(2)
  end

  it 'includes expected organizations failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Organization'").count).to eq(1)
  end

  it 'includes expected organizations validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Organization'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Organization'").count).to eq(2)
    end
  end

  it 'excludes expected organizations failures' do
    expect(GrdaWarehouse::Hud::Organization.where(OrganizationName: 'FAILURE').count).to eq(0)
  end

  # Project
  it 'includes expected projects' do
    expect(GrdaWarehouse::Hud::Project.count).to eq(2)
  end

  it 'includes expected projects failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Project'").count).to eq(2)
  end

  it 'includes expected projects validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Project'").count).to eq(7)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Project'").count).to eq(3)
    end
  end

  it 'excludes expected projects failures' do
    expect(GrdaWarehouse::Hud::Project.where(ProjectName: 'FAILURE').count).to eq(0)
  end

  # ProjectCoc
  it 'includes expected project_cocs' do
    expect(GrdaWarehouse::Hud::ProjectCoc.count).to eq(2)
  end

  it 'includes expected project_cocs failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%ProjectCoc'").count).to eq(2)
  end

  it 'includes expected project_cocs validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%ProjectCoc'").count).to eq(0)
      expect(HmisCsvImporter::HmisCsvValidation::ValidFormat.where("source_type LIKE '%ProjectCoc'").count).to eq(3)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%ProjectCoc'").count).to eq(1)
    end
  end

  it 'excludes expected project_cocs failures' do
    expect(GrdaWarehouse::Hud::ProjectCoc.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # Service
  it 'includes expected services' do
    expect(GrdaWarehouse::Hud::Service.count).to eq(2)
  end

  it 'includes expected services failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%Service'").count).to eq(2)
  end

  it 'includes expected services validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvImporter::HmisCsvValidation::InclusionInSet.where("source_type LIKE '%Service'").count).to eq(1)
      expect(HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where("source_type LIKE '%Service'").count).to eq(3)
    end
  end

  it 'excludes expected services failures' do
    expect(GrdaWarehouse::Hud::Service.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # User
  it 'includes expected users' do
    expect(GrdaWarehouse::Hud::User.count).to eq(2)
  end

  it 'includes expected users failures' do
    expect(HmisCsvImporter::HmisCsvValidation::NonBlank.where("source_type LIKE '%User'").count).to eq(1)
  end

  it 'excludes expected users failures' do
    expect(GrdaWarehouse::Hud::User.where(UserFirstName: 'FAILURE').count).to eq(0)
  end
end

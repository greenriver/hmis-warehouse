require 'rails_helper'

RSpec.describe 'Validate import files', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/validation_files'

    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)

    source_file_path = File.join(file_path, 'source')
    @import_path = File.join(file_path, @data_source.id.to_s)
    FileUtils.cp_r(source_file_path, @import_path)

    @loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: @import_path,
      data_source_id: @data_source.id,
      remove_files: false,
    )
    @loader.load!
    @loader.import!
  end

  after(:all) do
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!

    FileUtils.rm_rf(@import_path)
  end

  # Affiliations
  it 'includes expected affiliations' do
    expect(GrdaWarehouse::Hud::Affiliation.count).to eq(2)
  end

  it 'includes expected affiliations failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::Affiliation').count).to eq(2)
  end

  it 'excludes expected affiliations failures' do
    expect(GrdaWarehouse::Hud::Affiliation.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # Assessments
  it 'includes expected assessments' do
    expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
  end

  it 'includes expected assessments failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::Assessment').count).to eq(4)
  end

  it 'includes expected assessments validations' do
    expect(HmisCsvValidation::InclusionInSet.where(source_type: 'HmisCsvTwentyTwenty::Loader::Assessment').count).to eq(2)
  end

  it 'excludes expected assessments failures' do
    expect(GrdaWarehouse::Hud::Assessment.where(AssessmentID: 'FAILURE').count).to eq(0)
  end

  # AssessmentQuestions
  it 'includes expected assessment questions' do
    expect(GrdaWarehouse::Hud::AssessmentQuestion.count).to eq(2)
  end

  it 'includes expected assessment questions failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::AssessmentQuestion').count).to eq(3)
  end

  it 'excludes expected assessment questions validations' do
    expect(GrdaWarehouse::Hud::AssessmentQuestion.where(AssessmentQuestionID: 'FAILURE').count).to eq(0)
  end

  # AssessmentResults
  it 'includes expected assessment questions' do
    expect(GrdaWarehouse::Hud::AssessmentResult.count).to eq(2)
  end

  it 'includes expected assessment questions failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::AssessmentResult').count).to eq(3)
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
      expect(HmisCsvValidation::InclusionInSet.where(source_type: 'HmisCsvTwentyTwenty::Loader::Client').count).to eq(4)
      expect(HmisCsvValidation::NonBlankValidation.where(source_type: 'HmisCsvTwentyTwenty::Loader::Client').count).to eq(2)
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
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::CurrentLivingSituation').count).to eq(5)
  end

  it 'excludes expected current_living_situation failures' do
    expect(GrdaWarehouse::Hud::CurrentLivingSituation.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Disability
  it 'includes expected disabilities' do
    expect(GrdaWarehouse::Hud::Disability.count).to eq(2)
  end

  it 'includes expected disabilities failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::Disability').count).to eq(4)
  end

  it 'includes expected disabilities validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvValidation::InclusionInSet.where(source_type: 'HmisCsvTwentyTwenty::Loader::Disability').count).to eq(6)
      expect(HmisCsvValidation::NonBlankValidation.where(source_type: 'HmisCsvTwentyTwenty::Loader::Disability').count).to eq(1)
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
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::EmploymentEducation').count).to eq(2)
  end

  it 'includes expected employment educations validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvValidation::InclusionInSet.where(source_type: 'HmisCsvTwentyTwenty::Loader::EmploymentEducation').count).to eq(1)
      expect(HmisCsvValidation::NonBlankValidation.where(source_type: 'HmisCsvTwentyTwenty::Loader::EmploymentEducation').count).to eq(2)
    end
  end

  it 'excludes expected employment educations failures' do
    expect(GrdaWarehouse::Hud::EmploymentEducation.where(EnrollmentID: 'FAILURE').count).to eq(0)
  end

  # Enrollment
  it 'includes expected enrollments' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(2)
  end

  it 'includes expected enrollments failures' do
    expect(HmisCsvValidation::NonBlank.where(source_type: 'HmisCsvTwentyTwenty::Loader::Enrollment').count).to eq(3)
  end

  it 'includes expected enrollments validations' do
    aggregate_failures 'validating' do
      expect(HmisCsvValidation::InclusionInSet.where(source_type: 'HmisCsvTwentyTwenty::Loader::Enrollment').count).to eq(4)
      expect(HmisCsvValidation::NonBlankValidation.where(source_type: 'HmisCsvTwentyTwenty::Loader::Enrollment').count).to eq(4)
    end
  end

  it 'excludes expected enrollments failures' do
    expect(GrdaWarehouse::Hud::Enrollment.where(ProjectID: 'FAILURE').count).to eq(0)
  end

  # it 'has two entry after exit validation errors' do
  #   expect(HmisCsvValidation::EntryAfterExit.count).to eq(2)
  # end

  it 'does not include any Export errors' do
    expect(HmisCsvValidation::Base.where(source_type: 'HmisCsvTwentyTwenty::Loader::Export').count).to eq(0)
  end
end

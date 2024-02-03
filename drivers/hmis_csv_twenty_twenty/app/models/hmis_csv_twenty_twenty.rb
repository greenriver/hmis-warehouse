###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty
  def self.matches(file_path)
    # FIXME: Check all the file headers instead of just this one file
    expected_cols = HmisCsvTwentyTwenty::Loader::Project.hmis_structure(version: '2020').keys
    actual_cols = AutoEncodingCsv.read("#{file_path}/Project.csv", headers: true).headers
    expected_cols.map { |m| m.to_s.downcase }.sort == actual_cols.map { |m| m.to_s.downcase }.sort
  end

  def self.import!(file_path, data_source_id, upload, deidentified:)
    log = ::HmisCsvTwentyTwenty::ImportLog.create(
      created_at: Time.current,
      upload_id: upload.id,
      data_source_id: data_source_id,
    )
    loader = ::HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: file_path,
      data_source_id: data_source_id,
      deidentified: deidentified,
    )

    loader.import!(log)

    log
  end

  def self.enrollment_file_name
    'Enrollment.csv'
  end

  def self.client_related_file_names
    [
      'Client.csv',
      'Disabilities.csv',
      'EmploymentEducation.csv',
      'Enrollment.csv',
      'EnrollmentCoC.csv',
      'Exit.csv',
      'HealthAndDV.csv',
      'IncomeBenefits.csv',
      'Services.csv',
      'CurrentLivingSituation.csv',
      'Assessment.csv',
      'AssessmentQuestions.csv',
      'AssessmentResults.csv',
      'Event.csv',
    ]
  end

  def self.importable_files_map
    {
      'Export.csv' => 'Export',
      'Organization.csv' => 'Organization',
      'Project.csv' => 'Project',
      'Client.csv' => 'Client',
      'Disabilities.csv' => 'Disability',
      'EmploymentEducation.csv' => 'EmploymentEducation',
      'Enrollment.csv' => 'Enrollment',
      'EnrollmentCoC.csv' => 'EnrollmentCoc',
      'Exit.csv' => 'Exit',
      'Funder.csv' => 'Funder',
      'HealthAndDV.csv' => 'HealthAndDv',
      'IncomeBenefits.csv' => 'IncomeBenefit',
      'Inventory.csv' => 'Inventory',
      'ProjectCoC.csv' => 'ProjectCoc',
      'Affiliation.csv' => 'Affiliation',
      'Services.csv' => 'Service',
      'CurrentLivingSituation.csv' => 'CurrentLivingSituation',
      'Assessment.csv' => 'Assessment',
      'AssessmentQuestions.csv' => 'AssessmentQuestion',
      'AssessmentResults.csv' => 'AssessmentResult',
      'Event.csv' => 'Event',
      'User.csv' => 'User',
    }.freeze
  end
end

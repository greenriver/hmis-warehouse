###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter
  def self.import!(file_path, data_source_id, upload, deidentified:)
    log = ::HmisCsvImporter::ImportLog.new(
      created_at: Time.current,
      upload_id: upload.id,
      data_source_id: data_source_id,
    )
    loader = ::HmisCsvImporter::Loader::Loader.new(
      file_path: file_path,
      data_source_id: data_source_id,
      deidentified: deidentified,
    )

    loader.load!
    loader.import!

    log.assign_attributes(
      loader_log: loader.loader_log,
      importer_log: loader.importer_log,
      files: loader.loadable_files.transform_values(&:name).invert.to_a,
    )
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
      'YouthEducationStatus.csv',
    ]
  end
end

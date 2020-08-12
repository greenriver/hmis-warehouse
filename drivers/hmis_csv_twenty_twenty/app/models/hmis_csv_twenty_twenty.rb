###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty
  def self.matches(file_path)
    # The 2020 spec added the assessments csv
    File.exist?("#{file_path}/Assessment.csv")
  end

  def self.import!(file_path, data_source_id, upload, deidentified:, allowed_projects:) # rubocop:disable Lint/UnusedMethodArgument
    loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: file_path,
      data_source_id: data_source_id,
    )

    loader.load!
    loader.import!

    HmisCsvTwentyTwenty::ImportLog.new(
      upload_id: upload.id,
      data_source_id: data_source_id,
      summary: {},
      import_errors: {},
      files: loader.importable_files.importable_files.transform_values(&:name).invert.to_a,
    )
  end
end

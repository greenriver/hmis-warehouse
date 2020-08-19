###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty
  def self.matches(file_path)
    # FIXME: Check all the file headers instead of just this one file
    # The 2020 spec added the assessments csv
    File.exist?("#{file_path}/Assessment.csv")
  end

  def self.import!(file_path, data_source_id, upload, deidentified:, allowed_projects:) # rubocop:disable Lint/UnusedMethodArgument
    log = HmisCsvTwentyTwenty::ImportLog.new(
      created_at: Time.current,
      upload_id: upload.id,
      data_source_id: data_source_id,
    )
    loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: file_path,
      data_source_id: data_source_id,
    )

    loader.load!
    loader.import!

    log.assign_attributes(
      loader_log: loader.loader_log,
      importer_log: loader.importer_log,
      files: loader.importable_files.transform_values(&:name).invert.to_a,
    )
    log
  end
end

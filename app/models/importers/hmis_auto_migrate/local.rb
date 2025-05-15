###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'aws-sdk-rails'
require 'zip'
module Importers::HmisAutoMigrate
  class Local < Base
    attr_accessor :importer

    def initialize(
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      project_cleanup: true
    )
      setup_notifier('HMIS Local AutoMigrate Importer')
      @data_source_id = data_source_id
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = File.join(file_path, @data_source_id.to_s, Time.current.to_i.to_s)
      @project_cleanup = project_cleanup
    end

    def import!
      pre_process
      @importer = upload_zip_class.new(
        upload_id: @upload.id,
        data_source_id: @data_source_id,
        deidentified: @deidentified,
        allowed_projects: @allowed_projects,
        file_path: @file_path,
        project_cleanup: @project_cleanup,
      ).import!
    end

    delegate :loader_log, to: :importer
    delegate :importer_log, to: :importer

    def pre_process
      compress_and_upload
    end

    private def compress_and_upload
      # rezip files
      zip_file_path = File.join(@file_path, "#{@data_source_id}_#{Time.current.to_fs(:db)}.zip")
      files = Dir.glob(File.join(@file_path, '*')).map { |f| File.basename(f) }
      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(
            filename,
            File.join(@file_path, filename),
          )
        end
      end
      upload(file_path: zip_file_path)
    end

    private def upload_zip_class
      Importers::HmisAutoMigrate::UploadedZip
    end
  end
end

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
module Importers::HmisAutoDetect
  class UploadedZip
    def initialize(upload_id:, data_source_id:, deidentified: false, allowed_projects: false, file_path: 'tmp/hmis_import')
      @data_source_id = data_source_id
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = "#{@file_path}/#{@data_source_id}"
    end

    def import!
      @import_log = GrdaWarehouse::ImportLog.new(upload_id: @upload.id, data_source_id: @data_source_id, summary: {}, import_errors: {}, files: [])
      expand_upload
      importer = Importers::HmisAutoDetect.available_importers.detect{ |importer| importer.constantize.matches(@local_path) }
      if importer
        @upload.update(percent_complete: 1)
        @import_log = importer.constantize.import!(@file_path, @data_source_id, @upload, deidentified: @deidentified, allowed_projects: @allowed_projects)
        @upload.update(percent_complete: 100, completed_at: Time.current)
      else
        raise 'Unrecognized HMIS export format'
      end
    rescue Exception => e
      @import_log.import_errors = [{'message' => "#{e}"}]
      raise
    ensure
      FileUtils.rm_rf(@local_path) if File.exists?(@local_path)
      @import_log.completed_at = Time.current
      @import_log.save!
    end

    private def expand_upload
      file_path = reconstitute_upload
      Zip::File.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          entry.extract([@local_path, File.basename(entry.name)].join('/'))
        end
      end
    ensure
      FileUtils.rm(file_path)
    end

    private def reconstitute_upload
      reconstitute_path = "#{@local_path}/#{@upload.file.file.filename}"
      FileUtils.mkdir_p(@local_path) unless File.directory?(@local_path)
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(@upload.content)
      end
      reconstitute_path
    end
  end
end
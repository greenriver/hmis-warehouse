###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
module Importers::HmisAutoDetect
  class Base
    include NotifierConfig

    attr_accessor :notifier_config

    private def importer
      @importer ||= begin
        imp = Importers::HmisAutoDetect.available_importers.detect do |m|
          m.constantize.matches(@local_path)
        end
        raise 'Unrecognized HMIS export format' unless imp

        imp.constantize
      end
    end

    def import!
      upload_id = @upload&.id || 0
      import_log = GrdaWarehouse::ImportLog.new(
        upload_id: upload_id,
        data_source_id: @data_source_id,
        summary: {},
        import_errors: {},
        files: [],
      )
      # pre_process should do any cleanup of the zip file contents
      # and present a clean zip file in the @upload variable
      pre_process
      expand_upload
      @upload.update(percent_complete: 1)
      import_log = importer.import!(
        @local_path,
        @data_source_id,
        @upload,
        deidentified: @deidentified,
      )
      @upload.update(percent_complete: 100, completed_at: Time.current)
    rescue Exception => e
      import_log.import_errors = [{'message' => "#{e}"}]
      raise
    ensure
      FileUtils.rm_rf(@local_path) if File.exist?(@local_path)
      import_log.completed_at = Time.current
      import_log.save!
    end

    def log(message)
      @notifier&.ping(message)
      Rails.logger.info(message)
    end

    private def expand_upload
      zip_file = reconstitute_upload
      Zip::File.open(zip_file) do |zipped_file|
        zipped_file.each do |entry|
          entry.extract([@local_path, File.basename(entry.name)].join('/'))
        end
      end
    ensure
      FileUtils.rm(zip_file)
    end

    private def reconstitute_upload
      reconstitute_zip_file = File.join(@local_path, @upload.reload.file.file.filename)
      FileUtils.mkdir_p(@local_path) unless File.directory?(@local_path)
      File.open(reconstitute_zip_file, 'w+b') do |file|
        file.write(@upload.content)
      end
      reconstitute_zip_file
    end

    def upload(file_path:)
      user = User.setup_system_user()
      @upload = GrdaWarehouse::Upload.new(
        percent_complete: 0.0,
        data_source_id: @data_source_id,
        user_id: user.id,
      )
      add_content_to_upload_and_save(file_path: file_path)
    end

    private def add_content_to_upload_and_save(file_path:)
      @upload.file = Pathname.new(file_path).open
      @upload.content_type = @upload.file.content_type
      @upload.content = @upload.file.read
      @upload.save!
      @upload.id
    end
  end
end

require 'zip'
module Importers::HMISFiveOne
  class UploadedZip < Base
    #  Importers::HMISFiveOne::UploadedZip.new(data_source_id: 14, upload_id: 1)
    def initialize(
      file_path: 'var/hmis_import',
      data_source_id:,
      logger: Rails.logger, 
      debug: true,
      upload_id:
    )
      super(
        file_path: file_path, 
        data_source_id: data_source_id, 
        logger: logger, 
        debug: debug
      )
      @file_path = "#{file_path}/#{Time.now.to_i}"
      @local_path = "#{@file_path}/#{@data_source.id}"
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
    end

    def import!
      return unless @upload.present?
      file_path = reconstitute_upload()
      expand(file_path: file_path)
      super()
      mark_upload_complete()
    end

    def remove_import_files
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.exists?(@file_path)
    end
    
    def reconstitute_upload
      reconstitute_path = "#{@local_path}/#{@upload.file.file.filename}"
      Rails.logger.info "Re-constituting upload file to: #{reconstitute_path}"
      FileUtils.mkdir_p(@local_path) unless File.directory?(@local_path)
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(@upload.content)
      end
      reconstitute_path
    end
    
  end
end
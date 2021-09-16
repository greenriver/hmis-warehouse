###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
module Importers::HmisAutoMigrate
  class UploadedZip < Base
    def initialize(
      upload_id:,
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      file_password: nil
    )
      setup_notifier('HMIS Upload AutoMigrate Importer')
      @data_source_id = data_source_id
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = File.join(file_path, @data_source_id.to_s, Time.current.to_i.to_s)
      @file_password = file_password
      @post_processor = ->(_) { replace_original_upload_file }
    end

    def pre_process
      force_standard_zip
    end

    private def force_standard_zip
      zip_file = reconstitute_upload
      return unless File.extname(zip_file) == '.7z'

      tmp_folder = zip_file.gsub('.7z', '')
      dest_file = zip_file.gsub('.7z', '.zip')
      FileUtils.rmtree(tmp_folder) if File.exist? tmp_folder
      FileUtils.mkdir_p(tmp_folder)

      options = {}
      options = { password: @file_password } if @file_password.present?

      File.open(zip_file, 'rb') do |seven_zip|
        SevenZipRuby::Reader.open(seven_zip, options) do |szr|
          szr.extract_all(tmp_folder)
        end
      end
      # Cleanup original file
      FileUtils.rm(zip_file)
      # Make sure we don't have any old zip files around
      FileUtils.rm(dest_file) if File.exist? dest_file
      files = Dir.glob(File.join(tmp_folder, '*')).map { |f| File.basename(f) }
      Zip::File.open(dest_file, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(
            File.join(File.basename(tmp_folder), filename),
            File.join(tmp_folder, filename),
          )
        end
      end
      FileUtils.rmtree(tmp_folder) if File.exist? tmp_folder

      add_content_to_upload_and_save(file_path: dest_file)
    end

    private def replace_original_upload_file
      # rezip files
      zip_file_path = File.join(@local_path, @upload.file.file.filename)
      files = Dir.glob(File.join(@local_path, '*')).map { |f| File.basename(f) }
      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(
            filename,
            File.join(@local_path, filename),
          )
        end
      end

      add_content_to_upload_and_save(file_path: zip_file_path)
    end
  end
end

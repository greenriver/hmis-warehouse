###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
module Importers::HmisAutoDetect
  class UploadedZip < Base
    def initialize(
      upload_id:,
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      file_password: nil)
      setup_notifier('HMIS Upload AutoDetect Importer')
      @data_source_id = data_source_id
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = File.join(file_path, @data_source_id.to_s, Time.current.to_i.to_s)
      @file_password = file_password
    end

    def pre_process
      force_standard_zip
      remove_disallowed_projects_from_zip if @allowed_projects
    end

    private def remove_disallowed_projects_from_zip
      expand_upload
      calculate_allowed_personal_ids
      remove_disallowed_client_data
      replace_original_upload_file
      remove_import_files
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

    private def calculate_allowed_personal_ids
      @allowed_project_ids = GrdaWarehouse::WhitelistedProjectsForClients.
        where(data_source_id: @data_source_id).
        pluck(:ProjectID).
        to_set

      # 1. See if we have you in the database already (which would mean you were in one of those projects previously)
      @allowed_personal_ids = GrdaWarehouse::Hud::Client.
        where(data_source_id: @data_source_id).
        pluck(:PersonalID).
        to_set

      # 2. See if you have an enrollment in one of the allowed projects in the incoming file.
      file = File.join(@local_path, importer.enrollment_file_name)

      CSV.foreach(file, headers: true) do |row|
        @allowed_personal_ids.add(row['PersonalID']) if @allowed_project_ids.include?(row['ProjectID'])
      end
      log "Found #{@allowed_personal_ids.size} White-listed Personal IDs"
    end

    private def remove_disallowed_client_data
      importer.client_related_file_names.
        each do |filename|
          log "Removing un-white-listed rows from #{filename}"
          file = File.join(@local_path, filename)
          clean_file = File.join(@local_path, "clean_#{filename}")
          begin
            CSV.open(clean_file, 'wb') do |csv|
              line = File.open(file).readline
              # Make sure header is in our format
              csv << CSV.parse(line)[0].map {|k| k.downcase.to_sym}
              CSV.foreach(file, headers: true) do |row|
                # only keep row if PersonalID is in allowed clients
                csv << row if @allowed_personal_ids.include?(row['PersonalID'])
              end
            end
          rescue CSV::MalformedCSVError => e
            raise e unless CSV.read(clean_file).count == 1
          end
          FileUtils.mv(clean_file, file)
        end
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

    private def remove_import_files
      Rails.logger.info "Removing #{@local_path}"
      FileUtils.rm_rf(@local_path) if File.exists?(@local_path)
    end
  end
end

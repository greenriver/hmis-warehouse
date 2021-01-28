###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-rails'
require 'zip'
module Importers::HmisTwentyTwenty
  class S3 < Base
    def initialize(
      data_source_id:,
      region:,
      access_key_id:,
      secret_access_key:,
      bucket_name:,
      path:,
      file_path: 'var/hmis_import',
      logger: Rails.logger,
      debug: true,
      file_password: nil
    )
      super(
        file_path: file_path,
        data_source_id: data_source_id,
        logger: logger,
        debug: debug
      )

      @s3 = if secret_access_key.present? && secret_access_key != 'unknown'
        AwsS3.new(
          region: region,
          bucket_name: bucket_name,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
        )
      else
        AwsS3.new(
          region: region,
          bucket_name: bucket_name,
        )
      end
      @file_password = file_password
      @s3_path = path
      @file_path = "#{file_path}/#{Time.now.to_i}"
      @local_path = "#{@file_path}/#{@data_source.id}"
    end

    def self.available_connections
      GrdaWarehouse::HmisImportConfig.all.select do |conn|
        conn.s3_access_key_id.present? && conn.data_source.import_paused == false
      end
    end

    def import!
      file_path = copy_from_s3
      # For local testing
      # file_path = copy_from_local()
      upload(file_path: file_path) if file_path.present?
      expand(file_path: file_path)
      ensure_file_naming
      super()
      mark_upload_complete
    end

    def remove_import_files
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.exist?(@file_path)
    end

    def copy_from_s3
      return unless @s3.present?
      file = fetch_most_recent
      return unless file

      warn_of_unchanged_file(file)
      log("Found #{file}")
      # atool has trouble overwriting, so blow away whatever we had before
      FileUtils.rmtree(@local_path) if File.exist? @local_path
      FileUtils.mkdir_p(@local_path)
      target_path = "#{@local_path}/#{File.basename(file)}"
      log("Downloading to: #{target_path}")
      @s3.fetch(
        file_name: file,
        target_path: target_path,
      )
      file_path = force_standard_zip(target_path)
    end

    def warn_of_unchanged_file(file)
      incoming_filename = File.basename(file, File.extname(file))
      previous_import_filename = previous_import&.file&.file&.filename || 'none.zip'
      previous_import_filename = File.basename(previous_import_filename, File.extname(previous_import_filename))
      log("WARNING, filename has not changed since last import: #{incoming_filename}") if incoming_filename == previous_import_filename
    end

    def previous_import
      GrdaWarehouse::Upload.where(data_source_id: @data_source.id).select(:id, :file).order(id: :desc).first
    end

    def force_standard_zip file
      # puts file.inspect
      file_path = "#{Rails.root}/#{file}"
      if File.extname(file_path) == '.7z'
        dest_file = file.gsub('.7z', '.zip')
        tmp_folder = file.gsub('.7z', '')
        FileUtils.rmtree(tmp_folder) if File.exist? tmp_folder
        FileUtils.mkdir_p(tmp_folder)

        options = {}
        options = { password: @file_password } if @file_password.present?

        File.open(file_path, 'rb') do |seven_zip|
          SevenZipRuby::Reader.open(seven_zip, options) do |szr|
            szr.extract_all(tmp_folder)
          end
        end
        # Cleanup original file
        FileUtils.rm(file_path)
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
        file_path = dest_file
      end
      return file_path
    end

    def fetch_most_recent
      files = []
      @s3.fetch_key_list(prefix: @s3_path).sort.each do |entry|
        files << entry if entry.include?(@s3_path)
      end
      return nil if files.empty?

      # Fetch the most recent file
      file = files.first
      return file if file.present?

      nil
    end

    def upload(file_path:)
      user = User.setup_system_user
      @upload = GrdaWarehouse::Upload.new(
        percent_complete: 0.0,
        data_source_id: @data_source.id,
        user_id: user.id,
      )
      @upload.file = Pathname.new(file_path).open
      @upload.content_type = @upload.file.content_type
      @upload.content = @upload.file.read
      @upload.save
    end
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-rails'
require 'zip'
module Importers::HmisAutoDetect
  class S3 < Base
    def initialize(
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      region:,
      access_key_id:,
      secret_access_key:,
      bucket_name:,
      path:,
      file_password: nil
    )
      setup_notifier('HMIS S3 AutoDetect Importer')
      @data_source_id = data_source_id
      @deidentified = deidentified
      @allowed_projects = allowed_projects

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
      @file_path = file_path
      @local_path = File.join(file_path, @data_source_id.to_s, Time.current.to_i.to_s)
    end

    def self.available_connections
      GrdaWarehouse::HmisImportConfig.active.select do |conn|
        conn.s3_access_key_id.present? && conn.data_source.import_paused == false
      end
    end

    def pre_process
      file_path = copy_from_s3
      upload_id = upload(file_path: file_path) if file_path.present?
      Importers::HmisAutoDetect::UploadedZip.new(
        upload_id: upload_id,
        data_source_id: @data_source_id,
        deidentified: @deidentified,
        allowed_projects: @allowed_projects,
        file_path: @file_path,
        file_password: @file_password,
      ).pre_process
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
      target_path
    end

    def fetch_most_recent
      files = []
      # Returns oldest first
      @s3.fetch_key_list(prefix: @s3_path).each do |entry|
        files << entry if entry.include?(@s3_path)
      end
      return nil if files.empty?

      # Fetch the most recent file
      file = files.last
      return file if file.present?

      nil
    end

    private def previous_import
      GrdaWarehouse::Upload.where(data_source_id: @data_source_id).select(:id, :file).order(id: :desc).first
    end

    def warn_of_unchanged_file(file)
      incoming_filename = File.basename(file, File.extname(file))
      previous_import_filename = previous_import&.file&.file&.filename || 'none.zip'
      previous_import_filename = File.basename(previous_import_filename, File.extname(previous_import_filename))

      log("WARNING, filename has not changed since last import: #{incoming_filename}") if incoming_filename == previous_import_filename
    end
  end
end

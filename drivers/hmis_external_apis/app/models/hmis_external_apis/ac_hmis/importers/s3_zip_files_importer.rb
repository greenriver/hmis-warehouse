###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This class iterates over the zip file objects in a bucket "directory" and
# calls an importer on that directory after extraction.

module HmisExternalApis::AcHmis::Importers
  class S3ZipFilesImporter
    attr_accessor :bucket_name
    attr_accessor :prefix
    attr_accessor :importer_class
    attr_accessor :remote_credential
    attr_accessor :skip_lambda
    attr_accessor :found_csvs

    MPER_SLUG = 'mper'.freeze

    def initialize(bucket_name: nil)
      self.skip_lambda = ->(_s3_object) { false }
      self.found_csvs = []

      creds = GrdaWarehouse::RemoteCredentials::S3.active.find_by(slug: MPER_SLUG)
      self.remote_credential = creds
      self.bucket_name = creds&.bucket || bucket_name
      self.prefix = creds&.s3_prefix || ''
    end

    def self.run_mper?
      GrdaWarehouse::RemoteCredentials::S3.active.where(slug: MPER_SLUG).exists?
    end

    def self.mper
      s3_zip_files_importer = new
      s3_zip_files_importer.importer_class = ProjectsImporter
      s3_zip_files_importer.skip_lambda = ->(s3_object) do
        ProjectsImportAttempt.given(s3_object).to_skip.any?
      end

      s3_zip_files_importer.run!
    end

    def run!
      s3 = remote_credential&.s3 || AwsS3.new(bucket_name: bucket_name)

      # Choose which file to import (most recent)
      s3_object = s3.list_objects(prefix: prefix).first
      if !s3_object
        Rails.logger.info "No objects found in #{bucket_name}. Stopping."
        return
      end

      if skip_lambda.call(s3_object)
        # Note: to force re-run, delete the latest HmisExternalApis::AcHmis::Importers::ProjectsImportAttempt
        Rails.logger.info "Most recent file #{s3_object.key} was already imported, ignored, or failed. Stopping."
        return
      end

      # Down the file and run ProjectsImporter
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          Rails.logger.info "Fetching #{s3_object.key}"
          zip_file = s3.get_as_io(key: s3_object.key)

          Zip::InputStream.open(zip_file) do |zipfile|
            while (csv = zipfile.get_next_entry)
              next unless csv.file?

              Rails.logger.info "Found #{csv.name} in the archive."
              found_csvs << csv.name
              File.open(csv.name, 'w:ascii-8bit') do |f|
                f.write zipfile.read
              end
            end
          end

          importer_class.new(dir: '.', key: s3_object.key, etag: s3_object.etag).run! if importer_class.present?
        end
      end
    end
  end
end

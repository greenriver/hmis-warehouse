###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def initialize(bucket_name:)
      self.skip_lambda = ->(_s3_object) { false }
      self.found_csvs = []

      creds = GrdaWarehouse::RemoteCredentials::S3.find_by(slug: MPER_SLUG)
      self.remote_credential = creds
      self.bucket_name = creds&.bucket || bucket_name
      self.prefix = creds&.s3_prefix || ''
    end

    def self.run_mper?
      GrdaWarehouse::RemoteCredentials::S3.where(slug: MPER_SLUG).exists?
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

      s3.list_objects(prefix: prefix).each do |s3_object|
        unless s3_object.key.match?(/.zip$/i)
          Rails.logger.debug "Skipping a non-zip file #{s3_object.key}"
          next
        end

        if skip_lambda.call(s3_object)
          Rails.logger.debug "Skipping #{s3_object.key} that was already imported, ignored, or failed"
          next
        end

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
end

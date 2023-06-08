###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class ProjectsImporter
    attr_accessor :dir

    def initialize(dir:)
      self.dir = dir
    end

    def self.import_from_s3(bucket_name: ENV.fetch('ACTIVE_STORAGE_BUCKET'))
      Rails.logger.tagged('AcHmis projects importer') do
        s3 = AwsS3.new(bucket_name: bucket_name)

        s3.list_objects(prefix: 'mper').each do |s3_object|
          unless s3_object.key.match?(/.zip$/i)
            Rails.logger.debug "Skipping a non-zip file #{s3_object.key}"
            next
          end

          if ProjectsImportAttempt.given(s3_object).to_skip.any?
            Rails.logger.debug "Skipping #{s3_object.key} that was already imported, ignored, or failed"
            next
          end

          attempt = ProjectsImportAttempt.where(etag: s3_object.etag, key: s3_object.key).first_or_initialize
          attempt.attempted_at = Time.now

          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              Rails.logger.info "Fetching #{s3_object.key}"
              zip_file = s3.get_as_io(key: s3_object.key)

              Zip::InputStream.open(zip_file) do |zipfile|
                while (csv = zipfile.get_next_entry)
                  next unless csv.file?

                  Rails.logger.info "Found #{csv.name} in the archive."
                  File.open(csv.name, 'w:ascii-8bit') do |f|
                    f.write zipfile.read
                  end
                end
              end

              if Dir.glob("#{dir}/*csv").empty?
                msg = "No csv files were found in #{s3_object.key}"
                Rails.logger.error(msg)
                attempt.status = 'failed'
                attempt.result = { error: msg }
                attempt.save!
              else
                attempt.attempted_at = Time.now
                attempt.status = 'started'
                attempt.save!
                ProjectsImporter.new(dir: dir).run!
              end
            end
          end
        end
      end
    end

    def run!
      Rails.logger.tagged('AcHmis projects importer') do
        validate
      end
    end

    def validate
      Rails.logger.info 'Validating CSVs'
    end
  end
end

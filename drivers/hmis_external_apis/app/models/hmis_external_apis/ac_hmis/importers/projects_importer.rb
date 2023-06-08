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
      s3 = AwsS3.new(bucket_name: bucket_name)

      s3.list_objects(prefix: 'mper').each do |object|
        next unless object.key.match?(/.zip$/i)
        next if already_handled?(object)

        Dir.mktmpdir do |dir|
          Dir.chwd(dir) do
            s3_object = object.get.body
            Zip::InputStream.open(s3_object) do |zipfile|
              while (csv = zipfile.get_next_entry)
                next unless csv.file?

                Rails.logger.info "Found #{csv.name} in the archive."
                File.open(csv.name, 'w:ascii-8bit') do |f|
                  f.write zipfile.read
                end
              end
            end
            ProjectsImporter.new(dir: dir).run!
          end
        end
      end
    end

    def run!
      Rails.logger.tagged('AcHmis projects importer') do
      end
    end
  end
end

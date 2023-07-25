###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Migration
  class MciMappingImporterJob < ApplicationJob
    def perform
      HmisExternalApis::AcHmis::Importers::Migration::MciMappingImporter.new(io: io).run!
    end

    private

    def io
      bucket_name =
        case Rails.env
        when 'development' then 'dev-bucket'
        when 'test' then 'test-bucket'
        else
          ENV.fetch('S3_BUCKET_GENERAL', "#{ENV['AWS_CLIENT_NAME']}-#{ENV['AWS_APP_NAME']}-#{Rails.env}")
        end

      prefix = 'initial-migration/HMIS_MCI_UNIQ_ID-MCI_ID-mapping-'

      aws = AwsS3.new(bucket_name: bucket_name)

      best_result = aws.list_objects(prefix: prefix).first.tap do |object|
        raise "Could not find any files matching s3://#{bucket_name}/#{prefix}" if object.nil?
      end

      aws.get_as_io(key: best_result.key)
    end
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::CustomImports
  class Config < GrdaWarehouseBase
    acts_as_paranoid
    self.table_name = :custom_imports_config
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user

    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY'][0..31], attribute: 'encrypted_s3_secret'

    scope :for_data_source, ->(data_source) do
      where(data_source: data_source)
    end

    scope :active, -> do
      where(active: true)
    end

    def self.available_import_types
      Rails.application.config.custom_imports.map { |c| [c.constantize.description, c] }
    end

    def self.available_import_hours
      (0..23).map { |h| [Time.strptime(h.to_s, '%H').strftime('%l %P'), h] }
    end

    def list_objects(per_page = 25)
      s3.list_objects(per_page, prefix: s3_prefix)
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::AccessDenied, Aws::S3::Errors::SignatureDoesNotMatch => e
        raise FetchError, e.message
    end

    def s3
      @s3 ||= if s3_access_key_id.present? && s3_access_key_id != 'unknown'
        AwsS3.new(
          region: s3_region,
          bucket_name: s3_bucket,
          access_key_id: s3_access_key_id,
          secret_access_key: s3_secret_access_key,
        )
      else
        AwsS3.new(
          region: s3_region,
          bucket_name: s3_bucket_name,
        )
      end
    end

    def s3_path
      s3_prefix
    end

    def last_attempted
      last_import_attempted_at || 'Never'
    end

    def import_hour_description
      "Daily around: #{Time.strptime(import_hour.to_s, '%H').strftime('%l %P')}"
    end

    def import!
      import_type.constantize.new(config_id: id, data_source_id: data_source_id, status: 'queued').import!
    end
  end

  class FetchError < StandardError; end
end

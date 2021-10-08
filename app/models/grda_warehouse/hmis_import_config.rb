###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::HmisImportConfig < GrdaWarehouseBase
  has_paper_trail
  attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY'][0..31]
  attr_encrypted :zip_file_password, key: ENV['ENCRYPTION_KEY'][0..31]

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :active, -> do
    where(active: true)
  end

  def s3
    @s3 ||= if s3_secret_access_key.present? && s3_secret_access_key != 'unknown'
      AwsS3.new(
        region: s3_region,
        bucket_name: s3_bucket_name,
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
end

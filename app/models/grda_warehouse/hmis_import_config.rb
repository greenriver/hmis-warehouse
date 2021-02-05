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
    AwsS3.new(
      region: self.s3_region,
      bucket_name: self.s3_bucket_name,
      access_key_id: self.s3_access_key_id,
      secret_access_key: self.s3_secret_access_key,
    )
  end
end

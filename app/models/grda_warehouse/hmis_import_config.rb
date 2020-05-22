###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::HmisImportConfig < GrdaWarehouseBase
  has_paper_trail
  attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY']
  attr_encrypted :zip_file_password, key: ENV['ENCRYPTION_KEY']

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

end
###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Bo
  class Config < GrdaWarehouseBase
    self.table_name = :bo_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY'][0..31]

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
  end
end

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Bo
  class Config < GrdaWarehouseBase
    self.table_name = :bo_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY']

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name
  end
end

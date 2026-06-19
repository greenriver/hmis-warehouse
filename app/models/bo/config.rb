###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Bo
  class Config < GrdaWarehouseBase
    self.table_name = :bo_configs

    attr_encrypted :pass, key: ENV['ENCRYPTION_KEY'][0..31]

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
  end
end

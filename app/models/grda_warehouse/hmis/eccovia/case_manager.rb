###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class HMIS::Eccovia::ClientContact < GrdaWarehouseBase
    self.table_name = :eccovia_case_managers
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    acts_as_paranoid
  end
end

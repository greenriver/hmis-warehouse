###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class WhitelistedProjectsForClients < GrdaWarehouseBase
    has_one :data_source
    validates_presence_of :ProjectID, :data_source_id
  end
end

###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class WhitelistedProjectsForClients < GrdaWarehouseBase
    has_one :data_source
    validates_presence_of :ProjectID, :data_source_id
  end
end

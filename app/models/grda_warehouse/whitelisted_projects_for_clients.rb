###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class WhitelistedProjectsForClients < GrdaWarehouseBase
    has_one :data_source
    validates_presence_of :ProjectID, :data_source_id
  end
end

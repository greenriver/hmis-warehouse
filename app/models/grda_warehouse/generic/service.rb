###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Generic
  class Service < GrdaWarehouseBase
    self.table_name = :generic_services

    belongs_to :client
    belongs_to :data_source
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Vispdat
  class Child < GrdaWarehouseBase
    belongs_to :family, optional: true
  end
end

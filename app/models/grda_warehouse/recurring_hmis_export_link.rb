###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RecurringHmisExportLink < GrdaWarehouseBase
    belongs_to :hmis_export, optional: true
    belongs_to :recurring_hmis_export
  end
end

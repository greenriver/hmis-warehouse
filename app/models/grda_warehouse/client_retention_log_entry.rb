###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::ClientRetentionLogEntry < GrdaWarehouseBase
  ACTIONS = ['marked', 'unmarked', 'destination_removed'].freeze

  belongs_to :run, class_name: 'GrdaWarehouse::ClientRetentionRun', inverse_of: :log_entries

  validates :action, inclusion: { in: ACTIONS }
end

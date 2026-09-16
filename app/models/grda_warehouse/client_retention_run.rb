###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::ClientRetentionRun < GrdaWarehouseBase
  has_many :log_entries, class_name: 'GrdaWarehouse::ClientRetentionLogEntry', foreign_key: :run_id, inverse_of: :run

  scope :completed, -> { where.not(completed_at: nil) }
end

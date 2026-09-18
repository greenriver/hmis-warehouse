###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A warehouse identity whose retention window ends soon, as computed by the latest
# ClientRetentionJob run. Rows carry identifiers only and are replaced every run.
class GrdaWarehouse::ClientRetentionExpiringClient < GrdaWarehouseBase
  belongs_to :run, class_name: 'GrdaWarehouse::ClientRetentionRun', inverse_of: :expiring_clients

  scope :ordered, -> { order(expires_on: :asc, destination_client_id: :asc) }
end

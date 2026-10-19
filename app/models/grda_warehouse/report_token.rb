###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Read-only. Tokens are no longer issued; rows remain so old emailed links can redirect to the report.
module GrdaWarehouse
  class ReportToken < GrdaWarehouseBase
    belongs_to :report, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base', optional: true

    scope :active, -> { where(expires_at: Time.current..) }
  end
end

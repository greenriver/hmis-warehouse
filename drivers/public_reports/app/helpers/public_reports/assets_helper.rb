###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PublicReports::AssetsHelper
  def public_report_asset(name)
    File.read(Rails.root.join('drivers/public_reports/lib/public_reports/assets', name)).html_safe
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Side-nav entries for the HUD report pages: only the report definitions the
# current user has been granted.
module HudReports::ReportUrls
  extend ActiveSupport::Concern

  def report_urls
    @report_urls ||= GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(current_user).hud.
      order(:name).pluck(:name, :url).map { |name, url| [name, "/#{url}"] }
  end
end

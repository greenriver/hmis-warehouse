###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class DqsController < BaseController
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download, :restore]
    before_action :set_reports, except: [:index, :running_all_questions]
    before_action :set_pdf_export, only: [:show, :download]

    # Mounted at hud_reports/past_dqs; access follows the current DQ report.
    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(:dqs))
    end
  end
end

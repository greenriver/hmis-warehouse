###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class HouseholdController < OverviewController
    before_action :set_report
    before_action :set_key, only: [:details]

    def index
    end

    private def option_params
      params.permit(
        filters: [
          :key,
          :sub_key,
          :household,
          :sub_population,
          :project_type,
          :coordinated_assessment_living_situation_homeless,
          :coc,
          :breakdown,
        ],
      )
    end

    private def set_pdf_export
      @pdf_export = GrdaWarehouse::DocumentExports::HouseholdPerformanceExport.new
    end

    private def report_class
      PerformanceDashboards::Household
    end
  end
end

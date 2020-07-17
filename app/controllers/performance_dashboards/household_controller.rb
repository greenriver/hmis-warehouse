###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class HouseholdController < OverviewController
    before_action :set_filter
    before_action :set_report
    before_action :set_key, only: [:details]

    def index
    end

    def filters
      @sections = @report.control_sections
      chosen = params[:filter_section_id]
      if chosen
        @chosen_section = @sections.detect do |section|
          section.id == chosen
        end
      end
      @modal_size = :xl if @chosen_section.nil?
    end

    private def option_params
      params.permit(
        filters: [
          :key,
          :sub_key,
          :household,
          :sub_population,
          :project_type,
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

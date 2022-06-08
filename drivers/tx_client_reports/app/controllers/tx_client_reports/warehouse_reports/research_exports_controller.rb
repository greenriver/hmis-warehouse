###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::WarehouseReports
  class ResearchExportsController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :filter

    def index
      @rows = report.rows
      respond_to do |format|
        format.html do
          show_validations
          @pagy, @rows = pagy(@rows)
        end
        format.xlsx do
          filename = "Research Export - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def show_validations
      return unless params[:commit].present?

      flash[:error] = 'You must select a project or project group' unless show_report?
    end

    private def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(
          user_id: current_user.id,
          project_type_numbers: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS,
          enforce_one_year_range: false,
        )
        f.update(report_params)
        f
      end
    end

    private def show_report?
      filter.effective_project_ids.present? && filter.effective_project_ids != [0]
    end
    helper_method :show_report?

    private def report
      @report ||= TxClientReports::ResearchExport.new(@filter)
    end
    helper_method :report

    private def report_params
      return {} unless params[:filters].present?

      params.require(:filters).permit(::Filters::FilterBase.new.known_params)
    end
  end
end

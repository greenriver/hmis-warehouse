###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class HmisCrossWalksController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_filter

    def index
      @projects = GrdaWarehouse::Hud::Project.
        where(id: @filter.effective_project_ids).
        active_during(@filter.range).distinct
      @projects = @projects.with_project_type(@filter.project_type_ids) if @filter.project_type_numbers.any?
      @organizations = GrdaWarehouse::Hud::Organization.joins(:projects).merge(@projects).distinct
      @inventories = GrdaWarehouse::Hud::Inventory.within_range(@filter.range).joins(:project).merge(@projects).distinct
      @project_cocs = GrdaWarehouse::Hud::ProjectCoc.joins(:project).merge(@projects).distinct
      @funders = GrdaWarehouse::Hud::Funder.joins(:project).merge(@projects).distinct
      respond_to do |format|
        format.html {}
        format.xlsx {}
      end
    end

    private def set_filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id, enforce_one_year_range: false)
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      @filter.start = Date.new(year - 1, 10, 1) unless filter_params.dig(:filters, :start)
      @filter.end = Date.new(year, 9, 30) unless filter_params.dig(:filters, :end)
      @filter.set_from_params(filter_params[:filters].merge(enforce_one_year_range: false)) if filter_params[:filters].present?
    end

    private def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          coc_codes: [],
          project_type_numbers: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
    end
    helper_method :filter_params
  end
end

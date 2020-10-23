###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard::WarehouseReports
  class ScorecardsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_projects, :set_project_groups, :set_current_reports

    def show
      start_date = Date.current.prev_month.beginning_of_month
      end_date = Date.current.prev_month.end_of_month

      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
    end

    private def project_scope
      GrdaWarehouse::Hud::Project.viewable_by current_user
    end

    private def project_group_scope
      GrdaWarehouse::ProjectGroup.viewable_by current_user
    end

    private def reports_scope
      ProjectScorecard::Report
    end

    private def set_projects
      @projects = project_scope.joins(:organization, :data_source).
        order(p_t[:data_source_id].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc).
        preload(:contacts, :data_source, organization: :contacts).
        group_by { |m| [m.data_source.short_name, m.organization] }
    end

    private def set_project_groups
      @project_groups = project_group_scope.includes(:projects).
        order(name: :asc).
        preload(:contacts, projects: [organization: :contacts])
    end

    private def set_current_reports
      @current_reports = reports_scope.
        order(id: :asc).
        index_by(&:project_id)
    end

    # Override default to use show action
    private def related_report
      url = url_for(action: :show, only_path: true).sub(%r{^/}, '')
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
    end
  end
end

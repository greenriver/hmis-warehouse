###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module OverrideSummary
  class Report
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'override_summary/warehouse_reports/reports'
    end

    def title
      'Override Summary'
    end

    # @return filtered scope
    def report_scope
      scope = report_scope_source
      scope = scope.viewable_by(@filter.user)
      scope
    end

    def report_scope_source
      GrdaWarehouse::Hud::Project
    end

    def data
      @data ||= {}.tap do |by_project|
        all_projects.each do |project|
          k = project.organization_and_name(include_confidential_names: true)
          by_project[k] ||= {}
          by_project[k][:projects] ||= []
          by_project[k][:projects] << project if projects.key?(project.id)
          by_project[k][:inventories] = inventories[project] || []
          by_project[k][:project_cocs] = project_cocs[project] || []
        end
      end
    end

    private def all_projects
      @all_projects = (projects.values + project_cocs.keys + inventories.keys).uniq.sort_by(&:ProjectName)
    end

    private def projects
      @projects ||= GrdaWarehouse::Hud::Project.overridden.
        merge(report_scope).
        preload(:organization).
        index_by(&:id)
    end

    private def project_cocs
      @project_cocs ||= GrdaWarehouse::Hud::ProjectCoc.overridden.
        joins(:project).
        merge(report_scope).
        group_by(&:project)
    end

    private def inventories
      @inventories ||= GrdaWarehouse::Hud::Inventory.overridden.
        joins(:project).
        merge(report_scope).
        group_by(&:project)
    end
  end
end

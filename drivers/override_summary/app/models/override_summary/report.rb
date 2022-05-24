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
          project_name = project.name_and_type(include_confidential_names: true)
          organization_name = project.organization.OrganizationName
          by_project[organization_name] ||= {}
          by_project[organization_name][project_name] ||= {}
          by_project[organization_name][project_name][:projects] ||= []
          by_project[organization_name][project_name][:projects] << project if projects.key?(project.id)
          by_project[organization_name][project_name][:inventories] = inventories[project] || []
          by_project[organization_name][project_name][:project_cocs] = project_cocs[project] || []
        end
      end
    end

    def manual_data
      @manual_data ||= {}.tap do |md|
        funders = GrdaWarehouse::Hud::Funder.where(manual_entry: true).
          joins(project: :organization).
          preload(project: :organization)
        inventories = GrdaWarehouse::Hud::Inventory.where(manual_entry: true).
          joins(project: :organization).
          preload(project: :organization)
        project_cocs = GrdaWarehouse::Hud::ProjectCoc.where(manual_entry: true).
          joins(project: :organization).
          preload(project: :organization)

        if funders.exists?
          data = {}
          funders.each do |funder|
            org_name = funder.project.organization.OrganizationName
            project_name = funder.project.name_and_type(include_confidential_names: true)
            data[org_name] ||= {}
            data[org_name][project_name] ||= []
            data[org_name][project_name] << funder
          end
          md['Funder - Manual Records'] = data
        end

        if inventories.exists?
          data = {}
          inventories.each do |inventory|
            org_name = inventory.project.organization.OrganizationName
            project_name = inventory.project.name_and_type(include_confidential_names: true)
            data[org_name] ||= {}
            data[org_name][project_name] ||= []
            data[org_name][project_name] << inventory
          end
          md['Inventory - Manual Records'] = data
        end

        if project_cocs.exists?
          data = {}
          project_cocs.each do |project_coc|
            org_name = project_coc.project.organization.OrganizationName
            project_name = project_coc.project.name_and_type(include_confidential_names: true)
            data[org_name] ||= {}
            data[org_name][project_name] ||= []
            data[org_name][project_name] << project_coc
          end
          md['Project CoC - Manual Records'] = data
        end
      end
    end

    private def all_projects
      @all_projects = (projects.values + project_cocs.keys + inventories.keys).uniq.sort_by do |p|
        [
          p.organization.OrganizationName,
          p.ProjectName,
        ]
      end
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

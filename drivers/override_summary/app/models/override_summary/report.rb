###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Refactor:
# Pull all import overrides Pull Project and Organization where we can
# Left outer join to related record (might need to be done per table)
# Treat this more as a table
# Fetch visible project ids and limit what you can see when the override can be associated with a project
require 'memery'

module OverrideSummary
  class Report
    include Memery
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_reader :filter
    attr_accessor :override_ids # to support pagination

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
      scope = scope.viewable_by(filter.user)
      scope
    end

    def report_scope_source
      GrdaWarehouse::Hud::Project
    end

    # Overrides are visible to the user if they:
    # 1. Are in a data source for which the user has the`can_edit_projects` permission on at least one project
    def visible_overrides
      HmisCsvImporter::ImportOverride.joins(:data_source).
        preload(:data_source, :creator).
        merge(relevant_data_sources)
    end

    # Used for pagination.  Because calculation of use etc, is fairly expensive,
    # Call pagy on @report.visible_overrides, then set the `override_ids` on the report
    # and call override_scope within the report to only load data for the selected records
    def override_scope
      return visible_overrides unless override_ids&.any?

      visible_overrides.where(id: override_ids)
    end

    memoize def data
      lookups = HmisCsvImporter::ImportOverride.available_classes
      # Attempt to do as few queries as we can to fetch the projects
      data_by_file.each do |file_name, d|
        # Ignore any overrides to Export.csv, they'll never be related toa project
        next if file_name == 'Export.csv'
        # Ignore any overrides to User.csv, they'll never be related toa project
        next if file_name == 'User.csv'

        # Throw out any overrides that don't match a specific record (they'll match any project)
        d.each do |data_source_id, overrides|
          ids = overrides.keys.reject(&:blank?)

          # Fetch the related project names and add them to the projects key
          model = lookups[file_name][:model]
          scope = model.where(model.hud_key => ids, data_source_id: data_source_id)
          # Special case Organizations and Projects
          case file_name
          when 'Organization.csv'
            scope.left_outer_joins(:projects).find_each do |item|
              item.projects.each do |project|
                data_by_file[file_name][data_source_id][item[model.hud_key]][:projects] << project
              end
            end
          when 'Project.csv'
            scope.find_each do |item|
              data_by_file[file_name][data_source_id][item[model.hud_key]][:projects] << item
            end
          else
            scope.left_outer_joins(:project).find_each do |item|
              data_by_file[file_name][data_source_id][item[model.hud_key]][:projects] << item.project
            end
          end
        end
      end
      data_by_file
    end

    def data_by_file
      @data_by_file ||= {}.tap do |d|
        override_scope.find_each do |override|
          d[override.file_name] ||= {}
          d[override.file_name][override.data_source_id] ||= {}
          d[override.file_name][override.data_source_id][override.matched_hud_key] ||= { overrides: [], projects: [] }
          d[override.file_name][override.data_source_id][override.matched_hud_key][:overrides] << override
          d[override.file_name][override.data_source_id][override.matched_hud_key][:projects] = ['Any'] if override.matched_hud_key.blank?
        end
      end
    end

    private def relevant_data_sources
      return GrdaWarehouse::DataSource.none unless filter.user.can_edit_projects?

      GrdaWarehouse::DataSource.viewable_by(filter.user, permission: :can_edit_projects)
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
            project_name = funder.project.name_and_type(ignore_confidential_status: true)
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
            project_name = inventory.project.name_and_type(ignore_confidential_status: true)
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
            project_name = project_coc.project.name_and_type(ignore_confidential_status: true)
            data[org_name] ||= {}
            data[org_name][project_name] ||= []
            data[org_name][project_name] << project_coc
          end
          md['Project CoC - Manual Records'] = data
        end
      end
    end

    private def all_projects
      data = [
        projects.values,
        project_cocs.keys,
        inventories.keys,
        funders.keys,
        affiliations.keys,
        enrollments.keys,
        clients.keys,
      ]
      @all_projects = data.flatten.uniq.sort_by do |p|
        [
          p.organization.OrganizationName,
          p.ProjectName,
        ]
      end
    end
  end
end

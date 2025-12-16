###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Collections
    CONFIG = {
      supplemental_data_sets: CollectionConfig.new(
        key: :supplemental_data_sets,
        title: 'Supplemental Data Sets',
        source_class: 'HmisSupplemental::DataSet',
        name_method: :name,
        collection_scope: -> { HmisSupplemental::DataSet.order(:name, :id) },
        placeholder: 'Supplemental Data Set',
        css_class: 'jUserViewable jSupplementalDataSets',
        partial_name: 'supplemental_data_sets',
      ),
      cohorts: CollectionConfig.new(
        key: :cohorts,
        title: 'Cohorts',
        source_class: 'GrdaWarehouse::Cohort',
        name_method: :name,
        collection_scope: -> { GrdaWarehouse::Cohort.active.order(:name) },
        placeholder: 'Cohort',
        css_class: 'jUserViewable jCohorts',
        partial_name: 'cohorts',
      ),
      project_groups: CollectionConfig.new(
        key: :project_groups,
        title: 'Project Groups',
        source_class: 'GrdaWarehouse::ProjectGroup',
        name_method: :name,
        collection_scope: -> { GrdaWarehouse::ProjectGroup.order(:name) },
        placeholder: 'Project Group',
        css_class: 'jUserViewable jProjectCollections',
        partial_name: 'project_groups',
        extra_columns: [
          {
            header: 'Project Count',
            content: ->(entity) { ActionController::Base.helpers.number_with_delimiter(entity.projects.count) },
          },
        ],
      ),
      data_sources: CollectionConfig.new(
        key: :data_sources,
        title: 'Data Sources',
        source_class: 'GrdaWarehouse::DataSource',
        name_method: :name,
        collection_scope: -> { GrdaWarehouse::DataSource.source.order(:name) },
        placeholder: 'Data Source',
        css_class: 'jUserViewable jDataSources',
        partial_name: 'data_sources',
        extra_columns: [
          {
            header: 'Client Records',
            content: ->(entity) { ActionController::Base.helpers.number_with_delimiter(entity.clients.count) },
          },
          {
            header: 'Project Count',
            content: ->(entity) { ActionController::Base.helpers.number_with_delimiter(entity.projects.count) },
          },
          {
            header: 'Last Import',
            content: ->(entity) { entity.import_logs.maximum(:completed_at)&.localtime },
          },
        ],
      ),
      organizations: CollectionConfig.new(
        key: :organizations,
        title: 'Organizations',
        source_class: 'GrdaWarehouse::Hud::Organization',
        name_method: ->(org) { org.name(ignore_confidential_status: true) },
        collection_scope: -> do
          GrdaWarehouse::Hud::Organization.
            order(:name).
            preload(:data_source).
            group_by { |o| o.data_source&.name }
        end,
        placeholder: 'Organization',
        css_class: 'jUserViewable jOrganizations',
        partial_name: 'organizations',
        grouped: true,
        form_as: :grouped_select,
        form_group_method: :last,
        extra_columns: [
          {
            header: 'Data Source',
            content: ->(_entity, group_name) { group_name },
          },
          {
            header: 'Client Records',
            content: ->(entity, _group_name) { ActionController::Base.helpers.number_with_delimiter(entity.clients.count) },
          },
          {
            header: 'Project Count',
            content: ->(entity, _group_name) { ActionController::Base.helpers.number_with_delimiter(entity.projects.count) },
          },
        ],
      ),
      projects: CollectionConfig.new(
        key: :projects,
        title: 'Projects',
        source_class: 'GrdaWarehouse::Hud::Project',
        name_method: ->(project) { project.name(ignore_confidential_status: true) },
        collection_scope: -> do
          GrdaWarehouse::Hud::Project.
            order(:name).
            preload(:organization, :data_source).
            group_by { |p| "#{p.data_source&.name} / #{p.organization&.name(ignore_confidential_status: true)}" }
        end,
        placeholder: 'Project',
        css_class: 'jUserViewable jProjects',
        partial_name: 'projects',
        grouped: true,
        form_as: :grouped_select,
        form_group_method: :last,
        extra_columns: [
          {
            header: 'Data Source / Organization',
            content: ->(_entity, group_name) { group_name },
          },
        ],
      ),
      project_access_groups: CollectionConfig.new(
        key: :project_access_groups,
        title: 'Project Groups',
        source_class: 'GrdaWarehouse::ProjectAccessGroup',
        name_method: :name,
        collection_scope: -> { GrdaWarehouse::ProjectAccessGroup.order(:name) },
        placeholder: 'Project Group',
        css_class: 'jUserViewable jProjectAccessGroups',
        partial_name: 'project_access_groups',
        extra_columns: [
          {
            header: 'Project Count',
            content: ->(entity) { ActionController::Base.helpers.number_with_delimiter(entity.projects.count) },
          },
        ],
      ),
      coc_codes: CollectionConfig.new(
        key: :coc_codes,
        title: 'CoC Codes',
        source_class: 'GrdaWarehouse::Lookups::CocCode',
        name_method: :coc_code,
        collection_scope: -> { GrdaWarehouse::Lookups::CocCode.joins(:project_cocs).distinct.order(:coc_code) },
        placeholder: 'CoC',
        css_class: 'jUserViewable jCocCodes',
        partial_name: 'coc_codes',
        name_column: 'CoC',
        extra_columns: [
          {
            header: 'CoC Name',
            content: lambda(&:official_name),
          },
          {
            header: 'Project Count',
            content: ->(entity) { ActionController::Base.helpers.number_with_delimiter(entity.projects.count) },
          },
        ],
      ),
      reports: CollectionConfig.new(
        key: :reports,
        title: 'Reports',
        source_class: 'GrdaWarehouse::WarehouseReports::ReportDefinition',
        name_method: ->(rd) { "#{rd.report_group}: #{rd.name}" },
        collection_scope: -> do
          reports_scope = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled
          reports_scope.order(:report_group, :name).map do |rd|
            ["#{rd.report_group}: #{rd.name}", rd.id]
          end
        end,
        placeholder: 'Report',
        css_class: 'jUserViewable jReports',
        partial_name: 'reports',
        array_format: true,
        input_html_data: -> do
          reports_scope = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled
          {
            data: {
              unlimitable: reports_scope.
                where(limitable: false).
                pluck(:id).
                to_json,
            },
          }
        end,
      ),
    }.freeze
  end
end

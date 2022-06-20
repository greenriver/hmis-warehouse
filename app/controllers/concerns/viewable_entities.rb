###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This file is only used for user related entities, see
# Admin::GroupsController for those used in the access group pages
module ViewableEntities
  extend ActiveSupport::Concern
  included do
    # some helpers factored out of a view for the sake of readability

    private def data_source_viewability(base)
      {
        selected: @user.access_group.data_sources.pluck(:id), # Only show directly attached DS
        label: 'Data Sources',
        input_html: { class: 'jUserViewable jDataSources', name: "#{base}[data_sources][]" },
        collection: GrdaWarehouse::DataSource.source.viewable_by(current_user).order(:name),
        placeholder: 'Data Source',
        multiple: true,
      }
    end
    helper_method :data_source_viewability

    private def organization_viewability(base)
      model = GrdaWarehouse::Hud::Organization.viewable_by(current_user)
      collection = model.
        order(:name).
        joins(:data_source).
        group_by { |o| o.data_source&.name }
      {
        as: :grouped_select,
        group_method: :last,
        selected: @user.access_group.organizations.pluck(:id),
        collection: collection,
        label_method: ->(organization) { organization.name(ignore_confidential_status: true) },
        placeholder: 'Organization',
        multiple: true,
        input_html: {
          class: 'jUserViewable jOrganizations',
          name: "#{base}[organizations][]",
        },
      }
    end
    helper_method :organization_viewability

    private def project_viewability(base)
      model = GrdaWarehouse::Hud::Project.viewable_by(current_user)
      collection = model.
        order(:name).
        joins(:organization, :data_source).
        group_by { |p| "#{p.data_source&.name} / #{p.organization&.OrganizationName}" }
      {
        as: :grouped_select,
        group_method: :last,
        selected: @user.access_group.projects.pluck(:id),
        collection: collection,
        label_method: ->(project) { project.name_and_type(ignore_confidential_status: true) },
        placeholder: 'Project',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjects',
          name: "#{base}[projects][]",
        },
      }
    end
    helper_method :project_viewability

    private def coc_viewability(base)
      {
        label: 'CoC Codes',
        selected: @user.access_group.coc_codes,
        collection: GrdaWarehouse::Hud::ProjectCoc.distinct.distinct.order(:CoCCode).pluck(:CoCCode).compact,
        placeholder: 'CoC',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCocCodes',
          name: "#{base}[coc_codes][]",
        },
      }
    end
    helper_method :coc_viewability

    private def user_reports_assignability(base)
      model = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled.assignable_by(current_user)
      collection = model.order(:report_group, :name).map do |rd|
        ["#{rd.report_group}: #{rd.name}", rd.id]
      end
      unlimitable = model.where(limitable: false).pluck(:id)
      {
        selected: @user.access_group.reports.pluck(:id),
        collection: collection,
        placeholder: 'Report',
        multiple: true,
        input_html: {
          class: 'jUserViewable jReports',
          name: "#{base}[reports][]",
          data: { unlimitable: unlimitable.to_json },
        },
      }
    end
    helper_method :user_reports_assignability

    private def project_groups_editability(base)
      model = GrdaWarehouse::ProjectGroup.editable_by(current_user)
      collection = model.order(:name).pluck(:name, :id)
      {
        selected: @user.access_group.project_groups.pluck(:id),
        collection: collection,
        placeholder: 'Project Group',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjectGroups',
          name: "#{base}[project_groups][]",
        },
      }
    end
    helper_method :project_groups_editability

    private def cohort_editability(base)
      model = GrdaWarehouse::Cohort.active.editable_by(current_user)
      {
        selected: @user.access_group.cohorts.pluck(:id),
        collection: model.order(:name),
        placeholder: 'Cohort',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCohorts',
          name: "#{base}[cohorts][]",
        },
      }
    end
    helper_method :cohort_editability
  end
end

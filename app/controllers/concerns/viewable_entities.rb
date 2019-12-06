###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ViewableEntities
  extend ActiveSupport::Concern
  included do
    # some helpers factored out of a view for the sake of readability

    private def data_source_viewability(base)
      {
        selected: @user.data_sources.map(&:id),
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
        preload(:data_source).
        group_by { |o| o.data_source.name }
      {
        as: :grouped_select,
        group_method: :last,
        selected: @user.organizations.map(&:id),
        collection: collection,
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
        preload(:organization, :data_source).
        group_by { |p| "#{p.data_source&.name} / #{p.organization&.name}" }
      {
        as: :grouped_select,
        group_method: :last,
        selected: @user.projects.map(&:id),
        collection: collection,
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
        selected: @user.coc_codes,
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

    private def reports_assignability(base)
      model = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled.assignable_by(current_user)
      collection = model.order(:report_group, :name).map do |rd|
        ["#{rd.report_group}: #{rd.name}", rd.id]
      end
      unlimitable = model.where(limitable: false).pluck(:id)
      {
        selected: @user.reports.map(&:id),
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
    helper_method :reports_assignability

    private def project_groups_editability(base)
      model = GrdaWarehouse::ProjectGroup.editable_by(current_user)
      collection = model.order(:name).pluck(:name, :id)
      {
        selected: @user.project_groups.map(&:id),
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
        selected: @user.cohorts.map(&:id),
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

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class GroupsController < ApplicationController
    before_action :require_can_edit_access_groups!
    before_action :set_group, only: [:edit, :update, :destroy]
    before_action :set_entities, only: [:new, :edit, :create, :update]

    def index
      @groups = access_group_scope.order(:name)
      @pagy, @groups = pagy(@groups)
    end

    def new
      @group = access_group_scope.new
    end

    def create
      @group = access_group_scope.new
      @group.update(group_params)
      @group.set_viewables(viewable_params)
      @group.save
      respond_with(@group, location: admin_groups_path)
    end

    def edit
    end

    def update
      @group.update(group_params)
      @group.set_viewables(viewable_params)
      @group.save

      redirect_to({ action: :index }, notice: "Group #{@group.name} updated.")
    end

    def destroy
      @group.destroy
      redirect_to({ action: :index }, notice: "Group #{@group.name} removed.")
    end

    private def access_group_scope
      AccessGroup.general
    end

    private def group_params
      params.require(:access_group).permit(
        :name,
        coc_codes: [],
      ).tap do |result|
        result[:coc_codes] ||= []
      end
    end

    private def viewable_params
      params.require(:access_group).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        reports: [],
        cohorts: [],
        project_groups: [],
      )
    end

    private def set_group
      @group = access_group_scope.find(params[:id].to_i)
    end

    private def set_entities
      @data_sources = {
        selected: @group&.data_sources&.map(&:id) || [],
        label: 'Data Sources',
        collection: GrdaWarehouse::DataSource.source.order(:name),
        placeholder: 'Data Source',
        multiple: true,
        input_html: {
          class: 'jUserViewable jDataSources',
          name: 'access_group[data_sources][]',
        },
      }

      @organizations = {
        as: :grouped_select,
        group_method: :last,
        selected: @group&.organizations&.map(&:id) || [],
        collection: GrdaWarehouse::Hud::Organization.
          order(:name).
          preload(:data_source).
          group_by { |o| o.data_source&.name },
        label_method: ->(organization) { organization.name(ignore_confidential_status: true) },
        placeholder: 'Organization',
        multiple: true,
        input_html: {
          class: 'jUserViewable jOrganizations',
          name: 'access_group[organizations][]',
        },
      }

      @projects = {
        as: :grouped_select,
        group_method: :last,
        selected: @group&.projects&.map(&:id) || [],
        collection: GrdaWarehouse::Hud::Project.
          order(:name).
          preload(:organization, :data_source).
          group_by { |p| "#{p.data_source&.name} / #{p.organization&.name(ignore_confidential_status: true)}" },
        label_method: ->(project) { project.name(ignore_confidential_status: true) },
        placeholder: 'Project',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjects',
          name: 'access_group[projects][]',
        },
      }

      @cocs = {
        label: 'CoC Codes',
        selected: @group&.coc_codes || [],
        collection: GrdaWarehouse::Hud::ProjectCoc.distinct.distinct.order(:CoCCode).pluck(:CoCCode).compact,
        placeholder: 'CoC',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCocCodes',
          name: 'access_group[coc_codes][]',
        },
      }

      reports_scope = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled
      @reports = {
        selected: @group&.reports&.map(&:id) | [],
        collection: reports_scope.
          order(:report_group, :name).map do |rd|
            ["#{rd.report_group}: #{rd.name}", rd.id]
          end,
        placeholder: 'Report',
        multiple: true,
        input_html: {
          class: 'jUserViewable jReports',
          name: 'access_group[reports][]',
          data: {
            unlimitable: reports_scope.
              where(limitable: false).
              pluck(:id).
              to_json,
          },
        },
      }

      @project_groups = {
        selected: @group&.project_groups&.map(&:id) || [],
        collection: GrdaWarehouse::ProjectGroup.
          order(:name).
          pluck(:name, :id),
        placeholder: 'Project Group',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjectGroups',
          name: 'access_group[project_groups][]',
        },
      }

      @cohorts = {
        selected: @group&.cohorts&.map(&:id) || [],
        collection: GrdaWarehouse::Cohort.
          active.
          order(:name),
        placeholder: 'Cohort',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCohorts',
          name: 'access_group[cohorts][]',
        },
      }
    end
  end
end

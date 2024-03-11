###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class CollectionsController < ApplicationController
    before_action :require_can_edit_collections!
    before_action :set_collection, only: [:show, :edit, :update, :destroy, :entities]
    before_action :set_entities, only: [:new, :edit, :create, :update]

    def index
      @collections = collection_scope.order(:name)
      @pagy, @collections = pagy(@collections)
    end

    def show
    end

    def new
      @collection = collection_scope.new
    end

    def create
      @collection = collection_scope.new
      @collection.update(collection_params)
      @collection.set_viewables(viewable_params)
      @collection.save
      respond_with(@collection, location: admin_collection_path(@collection))
    end

    def edit
    end

    def update
      @collection.update(collection_params)
      @collection.set_viewables(viewable_params)
      @collection.save

      redirect_to({ action: :index }, notice: "Collection #{@collection.name} updated.")
    end

    def destroy
      @collection.destroy
      redirect_to({ action: :index }, notice: "Collection #{@collection.name} removed.")
    end

    def entities
    end

    private def collection_scope
      Collection.general
    end

    private def collection_params
      params.require(:collection).permit(
        :name,
        :description,
        :collection_type,
        coc_codes: [],
      ).tap do |result|
        result[:coc_codes] ||= []
      end
    end

    private def viewable_params
      params.require(:collection).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
        project_groups: [],
      )
    end

    private def set_collection
      @collection = collection_scope.find(params[:id].to_i)
    end

    private def set_entities
      @data_sources = {
        selected: @collection&.data_sources&.map(&:id) || [],
        label: 'Data Sources',
        collection: GrdaWarehouse::DataSource.source.order(:name),
        placeholder: 'Data Source',
        multiple: true,
        input_html: {
          class: 'jUserViewable jDataSources',
          name: 'collection[data_sources][]',
        },
      }

      @organizations = {
        as: :grouped_select,
        group_method: :last,
        selected: @collection&.organizations&.map(&:id) || [],
        collection: GrdaWarehouse::Hud::Organization.
          order(:name).
          preload(:data_source).
          group_by { |o| o.data_source&.name },
        label_method: ->(organization) { organization.name(ignore_confidential_status: true) },
        placeholder: 'Organization',
        multiple: true,
        input_html: {
          class: 'jUserViewable jOrganizations',
          name: 'collection[organizations][]',
        },
      }

      @projects = {
        as: :grouped_select,
        group_method: :last,
        selected: @collection&.projects&.map(&:id) || [],
        collection: GrdaWarehouse::Hud::Project.
          order(:name).
          preload(:organization, :data_source).
          group_by { |p| "#{p.data_source&.name} / #{p.organization&.name(ignore_confidential_status: true)}" },
        label_method: ->(project) { project.name(ignore_confidential_status: true) },
        placeholder: 'Project',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjects',
          name: 'collection[projects][]',
        },
      }

      @project_access_groups = {
        selected: @collection&.project_access_groups&.map(&:id) || [],
        collection: GrdaWarehouse::ProjectAccessGroup.
          order(:name).
          pluck(:name, :id),
        id: :project_access_groups,
        placeholder: 'Project Group',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjectAccessGroups',
          name: 'collection[project_access_groups][]',
        },
      }

      @cocs = {
        label: 'CoC Codes',
        selected: @collection&.coc_codes || [],
        collection: GrdaWarehouse::Hud::ProjectCoc.distinct.distinct.order(:CoCCode).pluck(:CoCCode).compact,
        placeholder: 'CoC',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCocCodes',
          name: 'collection[coc_codes][]',
        },
      }

      reports_scope = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled
      @reports = {
        selected: @collection&.reports&.map(&:id) | [],
        collection: reports_scope.
          order(:report_group, :name).map do |rd|
            ["#{rd.report_group}: #{rd.name}", rd.id]
          end,
        placeholder: 'Report',
        multiple: true,
        input_html: {
          class: 'jUserViewable jReports',
          name: 'collection[reports][]',
          data: {
            unlimitable: reports_scope.
              where(limitable: false).
              pluck(:id).
              to_json,
          },
        },
      }

      @project_groups = {
        selected: @collection&.project_groups&.map(&:id) || [],
        collection: GrdaWarehouse::ProjectGroup.
          order(:name).
          pluck(:name, :id),
        placeholder: 'Project Group',
        multiple: true,
        input_html: {
          class: 'jUserViewable jProjectCollections',
          name: 'collection[project_groups][]',
        },
      }

      @cohorts = {
        selected: @collection&.cohorts&.map(&:id) || [],
        collection: GrdaWarehouse::Cohort.
          active.
          order(:name),
        placeholder: 'Cohort',
        multiple: true,
        input_html: {
          class: 'jUserViewable jCohorts',
          name: 'collection[cohorts][]',
        },
      }
    end
  end
end

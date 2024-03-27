###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::GroupsController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled
  include AjaxModalRails::Controller

  before_action :require_hmis_admin_access!
  before_action :set_group, only: [:show, :edit, :update, :destroy, :entities, :bulk_entities]
  before_action :set_entities, only: [:new, :edit, :create, :update, :entities]

  def index
    @groups = access_group_scope.order(:name)
    @groups = @groups.text_search(params[:q]) if params[:q].present?
    @pagy, @groups = pagy(@groups)
  end

  def show
  end

  def new
    @group = access_group_scope.new
  end

  def create
    @group = access_group_scope.new
    @group.update(group_params)
    @group.save
    respond_with(@group, location: hmis_admin_group_path(@group))
  end

  def edit
  end

  def update
    @group.update(group_params)
    @group.save

    redirect_to({ action: :show }, notice: "Group #{@group.name} updated.")
  end

  def destroy
    @group.destroy
    redirect_to({ action: :index }, notice: "Group #{@group.name} removed.")
  end

  def entities
    @modal_size = :lg
    @entities = case params[:entities]&.to_sym
    when :data_sources
      @data_sources
    when :organizations
      @organizations
    when :projects
      @projects
    end
  end

  def bulk_entities
    ids = {}
    @group.entity_types.keys.each do |entity_type|
      values = bulk_entities_params.to_h.with_indifferent_access[entity_type]
      ids[entity_type] ||= []
      # Prevent unsetting other entity types
      if entity_type.to_s == params[:entities]
        values.each do |id, checked|
          id = id.to_i
          ids[entity_type] << id if checked == '1'
        end
      else
        ids[entity_type] = @group.send(entity_type).map(&:id)
      end
    end

    @group.set_viewables(ids.with_indifferent_access)
    redirect_to({ action: :show }, notice: "Collection #{@group.name} updated.")
  end

  private def access_group_scope
    Hmis::AccessGroup
  end

  private def group_params
    params.require(:access_group).permit(:name, :description)
  end

  private def viewable_params
    params.require(:access_group).permit(
      data_sources: [],
      organizations: [],
      projects: [],
      project_access_groups: [],
    )
  end

  private def bulk_entities_params
    params.require(:collection).permit(
      data_sources: {},
      organizations: {},
      projects: {},
    )
  end

  private def set_group
    @group = access_group_scope.find(params[:id].to_i)
  end

  private def set_entities
    @data_sources = {
      selected: @group&.data_sources&.map(&:id) || [],
      label: 'HMIS Data Sources',
      collection: GrdaWarehouse::DataSource.hmis.order(:name),
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
      collection: GrdaWarehouse::Hud::Organization.joins(:data_source).
        merge(GrdaWarehouse::DataSource.hmis).
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
      collection: GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(GrdaWarehouse::DataSource.hmis).
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

    # Add back once we have support for HMIS Project Groups.
    # @project_access_groups = {
    #   selected: @group&.project_access_groups&.map(&:id) || [],
    #   collection: GrdaWarehouse::ProjectAccessGroup.
    #     order(:name).
    #     pluck(:name, :id),
    #   id: :project_access_groups,
    #   placeholder: 'Project Group',
    #   multiple: true,
    #   input_html: {
    #     class: 'jUserViewable jProjectAccessGroups',
    #     name: 'access_group[project_access_groups][]',
    #   },
    # }
  end
end

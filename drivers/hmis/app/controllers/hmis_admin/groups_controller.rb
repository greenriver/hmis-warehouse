###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::GroupsController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
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
    respond_with(@group, location: hmis_admin_groups_path)
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
    Hmis::AccessGroup
  end

  private def group_params
    params.require(:access_group).permit(
      :name,
    )
  end

  private def viewable_params
    params.require(:access_group).permit(
      data_sources: [],
      organizations: [],
      projects: [],
      project_access_groups: [],
    )
  end

  private def set_group
    @group = access_group_scope.find(params[:id].to_i)
  end

  private def set_entities
    @data_sources = {
      selected: @group&.data_sources&.map(&:id) || [],
      label: 'Data Sources',
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

    @project_access_groups = {
      selected: @group&.project_access_groups&.map(&:id) || [],
      collection: GrdaWarehouse::ProjectAccessGroup.
        order(:name).
        pluck(:name, :id),
      id: :project_access_groups,
      placeholder: 'Project Group',
      multiple: true,
      input_html: {
        class: 'jUserViewable jProjectAccessGroups',
        name: 'access_group[project_access_groups][]',
      },
    }
  end
end

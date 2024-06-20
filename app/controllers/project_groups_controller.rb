###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_some_project_groups!
  before_action :require_can_import_project_groups!, only: [:maintenance, :import]
  before_action :set_project_group, only: [:edit, :update, :destroy]
  before_action :set_access, only: [:edit, :update]

  def index
    @project_groups = project_group_scope
    @project_groups = @project_groups.text_search(params[:q]) if params[:q].present?
    @pagy, @project_groups = pagy(@project_groups)
  end

  def new
    @project_group = project_group_source.new
    set_access
  end

  def create
    @project_group = project_group_source.new
    project_group_source.transaction do
      @project_group.assign_attributes(name: group_params[:name])
      filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params.merge(coc_codes: []))
      filter.coc_codes = []
      @project_group.options = filter.to_h
      if @project_group.save!
        editors = user_params[:editor_ids]&.reject(&:blank?)&.map(&:to_i)
        # If the user can't edit all project groups, make sure we add the user so they can access it later
        editors << current_user.id

        @project_group.replace_access(User.find(editors), scope: :editor)
        @project_group.maintain_projects!
        Collection.maintain_system_groups(group: :project_groups)

        # TODO: START_ACL remove when ACL transition complete
        users = user_params[:users]&.reject(&:empty?)&.map(&:to_i)
        users << current_user.access_group.id
        @project_group.update_access(users)
        AccessGroup.maintain_system_groups(group: :project_groups)
        # END_ACL
      end
    rescue Exception => e
      flash[:error] = e.message
      render action: :new
      return
    end
    respond_with(@project_group, location: edit_project_group_path(@project_group.id))
  end

  def edit
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def update
    project_group_source.transaction do
      @project_group.assign_attributes(name: group_params[:name])
      filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params)
      filter.coc_codes = []
      @project_group.options = filter.to_h
      if @project_group.save
        # START_ACL remove when ACL transition complete
        users = user_params[:users]&.reject(&:empty?)
        @project_group.update_access(users.map(&:to_i)) if users.present?
        # END_ACL
        if user_params.key?(:editor_ids)
          user_ids = user_params[:editor_ids]&.reject(&:empty?)&.map(&:to_i)
          @project_group.replace_access(User.where(id: user_ids).to_a, scope: :editor) if user_ids.present?
        end
        @project_group.maintain_projects!
      end
    rescue Exception => e
      flash[:error] = e.message
      render action: :edit
      return
    end
    respond_with(@project_group, location: edit_project_group_path)
  end

  def destroy
    project_group_source.transaction do
      @project_group.remove_from_group_viewable_entities!
      @project_group.destroy
    end
    AccessGroup.maintain_system_groups
    respond_with(@project_group, location: project_groups_path)
  end

  def delete_multiple
    group_ids = params[:selections]&.try(:[], :group)&.reject(&:empty?)&.map(&:to_i)
    redirect_to project_groups_path and return unless group_ids

    project_group_source.transaction do
      group_ids.each do |group|
        project_group = project_group_scope.find(group)
        project_group.remove_from_group_viewable_entities!
        project_group.destroy
      end
    end
    AccessGroup.maintain_system_groups
    redirect_to project_groups_path
  end

  def maintenance
  end

  def download
    @project_groups = project_group_scope
    @project_groups = @project_groups.text_search(params[:q]) if params[:q].present?

    headers['Content-Disposition'] = "attachment; filename=Project Groups - #{Date.current.strftime('%Y-%m-%d')}.xlsx"
  end

  def import
    file = maintenance_params[:file]
    errors = project_group_source.import_csv(file)
    if errors.any?
      @errors = errors
      render action: :maintenance
    else
      flash[:notice] = 'Project groups imported'
      redirect_to action: :index
    end
  end

  private def maintenance_params
    params.require(:import).permit(:file)
  end

  def filter_params
    params.require(:filters).permit(::Filters::HudFilterBase.new(user_id: current_user.id).known_params)
  end

  def group_params
    params.require(:filters).
      permit(
        :name,
      )
  end

  def user_params
    params.require(:filters).
      permit(
        users: [],
        editor_ids: [],
      )
  end

  def set_project_group
    @project_group = project_group_source.find(params[:id].to_i)
  end

  def set_access
    @editor_ids = @project_group.editable_access_control.user_ids
    # TODO: START_ACL remove when ACL transition complete
    @groups = @project_group.access_groups
    @group_ids = @project_group.access_group_ids
    # END_ACL
  end

  def project_group_source
    GrdaWarehouse::ProjectGroup
  end

  def project_group_scope
    project_group_source.
      editable_by(current_user).
      includes(:projects).order(name: :asc)
  end

  def flash_interpolation_options
    { resource_name: 'Project Group' }
  end
end

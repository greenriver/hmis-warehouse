###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  private def any_invisible_projects?
    # Alert if there are projects in the project group that the user can't access, for now, let them proceed,
    # but note that there will be data loss
    previously_selected_project_ids = @project_group.projects.pluck(:id)
    viewable_project_ids = GrdaWarehouse::Hud::Project.viewable_by(current_user).pluck(:id)

    (previously_selected_project_ids - viewable_project_ids).any?
  end
  helper_method :any_invisible_projects?

  def new
    @project_group = project_group_source.new
    set_group_access
  end

  def create
    begin
      @project_group = project_group_source.new
      project_group_source.transaction do
        @project_group.assign_attributes(name: group_params[:name], notes: group_params[:notes])
        filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params.merge(coc_codes: []))
        filter.coc_codes = []
        limit_selections_to_viewable(filter)
        @project_group.options = filter.to_h
        @project_group.save!
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
    rescue StandardError => e
      flash[:error] = e.message
      render action: :new
      raise e if Rails.env.test?

      return
    end

    respond_with(@project_group, location: edit_project_group_path(@project_group.id))
  end

  def edit
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def update
    begin
      project_group_source.transaction do
        @project_group.assign_attributes(name: group_params[:name], notes: group_params[:notes])
        filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params)
        filter.coc_codes = []
        limit_selections_to_viewable(filter)
        @project_group.options = filter.to_h
        @project_group.save!
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
    rescue StandardError => e
      flash[:error] = e.message
      render action: :edit
      return
    end
    respond_with(@project_group, location: edit_project_group_path)
  end

  def destroy
    unless @project_group.available_for_delete?
      flash[:error] = "#{@project_group.name} cannot be deleted, it is used to populate a cohort, or in determining CAS availability."
      redirect_to edit_project_group_path(@project_group)
      return
    end

    destroyed = nil
    project_group_source.transaction do
      @project_group.remove_from_group_viewable_entities!
      destroyed = @project_group.destroy
    end
    # Collection/AccessControl/UserGroup live in the primary database, so this
    # teardown is NOT covered by the warehouse transaction above — run it only
    # after the warehouse delete has committed.
    @project_group.remove_system_collections! if destroyed
    AccessGroup.maintain_system_groups
    respond_with(@project_group, location: project_groups_path)
  end

  def delete_multiple
    group_ids = params[:selections]&.try(:[], :group)&.reject(&:empty?)&.map(&:to_i)
    redirect_to project_groups_path and return unless group_ids

    destroyed_groups = []
    skipped_groups = []
    project_group_source.transaction do
      group_ids.each do |group|
        project_group = editable_project_group_scope.find(group)
        unless project_group.available_for_delete?
          skipped_groups << project_group
          next
        end

        project_group.remove_from_group_viewable_entities!
        destroyed = project_group.destroy
        destroyed_groups << project_group if destroyed
      end
    end
    # primary-database teardown, outside the warehouse transaction
    destroyed_groups.each(&:remove_system_collections!)
    AccessGroup.maintain_system_groups
    if skipped_groups.any?
      skipped_names = skipped_groups.map(&:name).to_sentence
      flash[:error] = "Some project groups were not deleted because they are used to populate a cohort, or in determining CAS availability: #{skipped_names}"
    end
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

  # Saved options are resolved against every project (`Filters::SystemProjectHudFilter`), so a
  # save keeps only what the form's pickers offer this editor:
  # - Projects, organizations, and data sources: only ones the editor can see. The edit page
  #   warns that saving drops the rest.
  # - Excluded projects: the editor's visible picks, plus the group's saved exclusions the editor
  #   can't see, since dropping an exclusion would add its project back.
  # - Project groups: cleared. The form has no project group picker.
  # Project types aren't limited, so a type selection can still add projects the editor can't see.
  private def limit_selections_to_viewable(filter)
    viewable_projects = GrdaWarehouse::Hud::Project.viewable_by(current_user)
    viewable_organizations = GrdaWarehouse::Hud::Organization.viewable_by(current_user)
    viewable_data_sources = GrdaWarehouse::DataSource.viewable_by(current_user)

    saved_excluded_ids = clean_ids(@project_group.filter.excluded_project_ids)
    hidden_saved_excluded_ids = saved_excluded_ids - viewable_ids(viewable_projects, saved_excluded_ids)

    filter.project_ids = viewable_ids(viewable_projects, filter.project_ids)
    filter.excluded_project_ids = viewable_ids(viewable_projects, filter.excluded_project_ids) | hidden_saved_excluded_ids
    filter.organization_ids = viewable_ids(viewable_organizations, filter.organization_ids)
    filter.data_source_ids = viewable_ids(viewable_data_sources, filter.data_source_ids)
    filter.project_group_ids = []
  end

  private def viewable_ids(viewable_scope, submitted_ids)
    submitted_ids = clean_ids(submitted_ids)
    return [] if submitted_ids.empty?

    viewable_scope.where(id: submitted_ids).pluck(:id)
  end

  private def clean_ids(ids)
    Array.wrap(ids).reject(&:blank?).map(&:to_i)
  end

  def filter_params
    params.require(:filters).permit(::Filters::HudFilterBase.new(user_id: current_user.id).known_params)
  end

  def group_params
    params.require(:filters).
      permit(
        :name,
        :notes,
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
    @project_group = editable_project_group_scope.find(params[:id].to_i)
  end

  def set_access
    @editor_ids = @project_group.editable_access_control.user_ids
    set_group_access
  end

  def set_group_access
    # TODO: START_ACL remove when ACL transition complete
    @groups = @project_group.access_groups
    @group_ids = @project_group.access_group_ids
    # END_ACL
  end

  def project_group_source
    GrdaWarehouse::ProjectGroup
  end

  def editable_project_group_scope
    project_group_source.editable_by(current_user)
  end

  def project_group_scope
    editable_project_group_scope.
      includes(:projects).order(name: :asc)
  end

  def flash_interpolation_options
    { resource_name: 'Project Group' }
  end
end

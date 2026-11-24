###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CohortsController < ApplicationControllerV2
  include AjaxModalRails::Controller
  include CohortAuthorization
  include CohortClients
  include Search
  before_action :load_cohort, only: [:show, :edit, :update, :destroy, :maintain]
  authorize_with(only: :index) { current_user.can_access_some_cohorts }
  authorize_with(only: [:new, :create]) { current_user.can_create_cohorts? }
  authorize_with(only: :show) { cohort_policy.can_view? }
  authorize_with(only: [:edit, :update, :destroy, :maintain]) { cohort_policy.can_configure? }
  before_action :set_users, only: [:edit, :update, :destroy, :show]
  before_action :set_groups, only: [:edit, :update, :destroy, :show] # TODO: START_ACL remove when ACL transition complete
  before_action :set_thresholds, only: [:show]
  before_action :set_assessment_types, only: [:edit]

  def index
    scope = cohort_scope
    if params[:visible_on_dashboard].present?
      scope = scope.show_on_client_dashboard
      @visible_on_dashboard = true
      @active_filter = true
    end
    if params[:visible_in_cas].present?
      scope = scope.visible_in_cas
      @visible_in_cas = true
      @active_filter = true
    end

    @search = search_setup(columns: [:name], scope: :cohort_search)
    # Enforce visibility on searches
    @search = @search.where(id: scope.select(:id))
    current_user.policy_context.preload_cohort_dependencies(scope.pluck(:id))
    # A client id match reveals who is on a cohort, so it only searches cohorts the user can view
    if @search_string.present? && @search_string.to_i.to_s == @search_string.to_s
      viewable_ids = scope.select { |cohort| cohort_policy_for(cohort).can_view? }.map(&:id)
      @search = @search.where(id: viewable_ids)
    end
    @cohorts = @search.active_user.reorder(sort_string)
    @inactive_cohorts = @search.inactive.reorder(sort_string).select { |cohort| cohort_policy_for(cohort).can_configure? }
    @system_cohorts = if ::GrdaWarehouse::Config.get(:enable_system_cohorts)
      @search.system_cohorts.reorder(sort_string)
    else
      scope.none
    end
  end

  private def cohort_scope
    GrdaWarehouse::Cohort.listable_by(current_user)
  end

  private def search_scope
    cohort_scope
  end

  def show
    @per_page_js = [
      'cohorts',
    ]
    @modal_size = :xl
    params[:population] ||= 'Active Clients'
    load_cohort_names
    # Just fetch one client so the UI works, but we really are just using @cohort_clients in this context
    # to determine if there is anyone on the page we're looking at
    @cohort_clients = @cohort.search_clients(population: params[:population], user: current_user).limit(1)
    # redirect_to cohorts_path(population: ) if @cohort.needs_client_search?
    @cohort_client_updates = @cohort.cohort_clients.select(:id, :updated_at).map { |m| [m.id, m.updated_at.to_i] }.to_h
    @population = params[:population]

    respond_to do |format|
      format.html do
        @excel_export = GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport.new
        @visible_columns = [CohortColumns::Meta.new]
        @visible_columns += @cohort.visible_columns(user: current_user)
        delete_column = if @cohort.deleted_clients_tab?(@population)
          CohortColumns::Delete.new(title: 'Restore')
        else
          CohortColumns::Delete.new
        end
        @visible_columns << delete_column if cohort_policy.can_add_clients? && ! @cohort.system_cohort && ! @cohort.auto_maintained?
        @column_headers = @visible_columns.each_with_index.map do |col, index|
          col.cohort = @cohort # Needed for display_as_editable?
          description = if col.show_description? then col.description else '' end
          header = {
            headerName: col.title,
            headerTooltip: description,
            field: col.column,
            editable: col.column_editable? && col.display_as_editable?(current_user, nil),
          }
          header[:pinned] = :left if index <= @cohort.static_column_count
          header[:renderer] = col.renderer
          case col.renderer
          when 'dropdown'
            # header.merge!({type: col.renderer, source: col.available_header})
            # Be more forgiving of drop-down data
            header[:available_options] = [''] + col.available_options
          end
          header
        end
        @column_options = @visible_columns.map do |m|
          options = {
            data: "#{m.column}.value",
          }
          options[:dateFormat] = m.date_format if m.date_format.present?

          case m.renderer
          when 'dropdown'
            # options.merge!({type: m.renderer, source: m.available_options})
            # Be more forgiving of drop-down data
            options.merge!(type: 'autocomplete', source: m.available_options, strict: false, filter: false)
          when 'date', 'checkbox', 'text', 'numeric'
            options[:type] = m.renderer
          else
            options[:renderer] = m.renderer
            options[:readOnly] = true unless m.editable
          end
          options
        end

        # included so the excel download can be regenerated when the visible columns change
        digest = Digest::MD5.hexdigest(@visible_columns.to_s + @cohort.search_clients(population: @population, user: current_user).count.to_s)
        params['cache_key'] = digest
      end
    end
  end

  def new
    @cohort = cohort_source.new
    @users = User.active.not_system
  end

  def edit
    @modal_size = :xl
  end

  def destroy
    destroyed = @cohort.destroy unless @cohort.system_cohort
    @cohort.remove_system_collections! if destroyed
    redirect_to cohorts_path
  end

  def create
    GrdaWarehouse::Cohort.transaction do
      ApplicationRecord.transaction do
        cohort_options = cohort_params.except(:user_ids, :participant_ids, :viewer_ids, :manager_ids)
        @cohort = cohort_source.create!(viewable_project_group_options(cohort_options))
        # TODO: START_ACL remove when ACL transition complete
        current_user.access_group.add_viewable(@cohort) unless AccessGroup.system_group(:cohorts).users.include?(current_user)
        # END_ACL

        apply_submitted_access
        # Always add the cohort to the system group
        AccessGroup.maintain_system_groups(group: :cohorts)
        # Add default tabs
        GrdaWarehouse::CohortTab.default_rules.each do |rule|
          @cohort.cohort_tabs.create(**rule)
        end
      end
    end
    # Search the list so you can see the newly created cohort
    redirect_to cohorts_path('search_form[q]' => @cohort.name)
  rescue Exception => e
    flash[:error] = e.message
    redirect_to cohorts_path
  end

  def update
    # TODO: START_ACL replace when ACL transition complete
    # cohort_options = cohort_params.except(:participant_ids, :viewer_ids)
    cohort_options = cohort_params.except(:user_ids, :participant_ids, :viewer_ids, :manager_ids)
    # END_ACL
    cohort_options = cohort_options.except(:name) if @cohort.system_cohort

    cohort_options = viewable_project_group_options(cohort_options, current_project_group_id: @cohort.project_group_id)

    # The cohort is a warehouse record, access groups are app records; both must roll back together
    saved = GrdaWarehouse::Cohort.transaction do
      ApplicationRecord.transaction do
        next false unless @cohort.update(cohort_options)

        # TODO: START_ACL remove when ACL transition complete
        if cohort_params.key?(:user_ids)
          user_ids = Array(cohort_params[:user_ids]).select(&:present?).map(&:to_i)
          @cohort.update_access(user_ids)
        end
        # END_ACL

        apply_submitted_access
        @cohort.rename_manager_group
        true
      end
    end

    @cohort.delay.maintain if saved && @cohort.auto_maintained?
    respond_with(@cohort, location: saved ? location_after_update : nil)
  end

  # A project group is kept only if the user can view it or it is already the cohort's group.
  private def viewable_project_group_options(options, current_project_group_id: nil)
    project_group_id = options[:project_group_id]
    return options if project_group_id.blank?
    return options if GrdaWarehouse::ProjectGroup.viewable_by(current_user).exists?(project_group_id)
    return options if current_project_group_id == project_group_id.to_i

    options.except(:project_group_id)
  end

  # The policy memoized on current_user predates any access change made by this request
  private def location_after_update
    policy = User.find(current_user.id).policy_for(@cohort)
    if policy.can_view?
      cohort_path(@cohort)
    elsif policy.can_configure?
      edit_cohort_path(@cohort)
    else
      cohorts_path
    end
  end

  # Applies each submitted picker list; a list whose key is absent is left alone and an empty list removes everyone
  private def apply_submitted_access
    { editor: :participant_ids, viewer: :viewer_ids, manager: :manager_ids }.each do |scope, key|
      next unless cohort_params.key?(key)

      ids = Array(cohort_params[key]).reject(&:blank?)
      @cohort.replace_access(User.active.not_system.where(id: ids).to_a, scope: scope)
    end
  end

  def maintain
    if @cohort.auto_maintained?
      @cohort.delay.maintain
      flash[:notice] = 'Cohort maintenance queued.'
    else
      flash[:alert] = 'This cohort is manually maintained.'
    end

    redirect_to cohort_policy.can_view? ? cohort_path(@cohort) : edit_cohort_path(@cohort)
  end

  def cohort_params
    opts = [
      :name,
      :short_name,
      :description,
      :owner_id,
      :effective_date,
      :visible_state,
      :days_of_inactivity,
      :default_sort_direction,
      :only_window,
      :active_cohort,
      :static_column_count,
      :show_on_client_dashboard,
      :expose_inactive_on_client_dashboard,
      :visible_in_cas,
      :assessment_trigger,
      :tag_id,
      :project_group_id,
      :automation_sub_population,
      :automation_hoh_only,
      :enforce_project_visibility_on_cells,
      user_ids: [], # TODO: START_ACL remove when ACL transition complete
      participant_ids: [],
      viewer_ids: [],
      manager_ids: [],
    ] + GrdaWarehouse::Cohort.threshold_keys
    params.require(:cohort).permit(opts)
  end

  def set_assessment_types
    @assessment_types ||= begin # rubocop:disable  Naming/MemoizedInstanceVariableName
      types = []
      if current_user.can_view_vspdat?
        types += [
          ['Youth VI-SPDAT', GrdaWarehouse::Vispdat::Youth],
          ['Individual VI-SPDAT', GrdaWarehouse::Vispdat::Individual],
          ['Family VI-SPDAT', GrdaWarehouse::Vispdat::Family],
        ]
      end
      types << ['Individual CE Assessment', GrdaWarehouse::CoordinatedEntryAssessment::Individual] if current_user.can_view_ce_assessment?

      types
    end
  end

  # @thresholds is an array of objects
  private def set_thresholds
    thresholds = @cohort.attributes.select do |k, v|
      k.in?(GrdaWarehouse::Cohort.threshold_keys) && v.present?
    end
    @thresholds = (1..GrdaWarehouse::Cohort.visible_thresholds).map do |i|
      row = thresholds["threshold_row_#{i}"]
      label = thresholds["threshold_label_#{i}"]
      color = thresholds["threshold_color_#{i}"]
      next unless row && label && color

      {
        row: row,
        label: label,
        color: color,
      }
    end.compact.sort_by { |r| r[:row] }
  end

  private def table_params
    params.permit(:population)
  end
  helper_method :table_params

  def cohort_id
    params[:id].to_i
  end

  def load_cohort_names
    @cohort_names ||= cohort_source.pluck(:id, :name, :short_name). # rubocop:disable  Naming/MemoizedInstanceVariableName
      map do |id, name, short_name|
      [id, short_name.presence || name]
    end.to_h
  end

  def flash_interpolation_options
    { resource_name: @cohort&.name }
  end

  def sort_options
    [
      { title: 'Cohort Names A-Z', column: 'name', direction: 'asc', order: 'LOWER(name) ASC' },
      { title: 'Cohort Names Z-A', column: 'name', direction: 'desc', order: 'LOWER(name) DESC' },
      { title: 'Effective Date Ascending', column: 'effective_date', direction: 'asc', order: 'effective_date ASC' },
      { title: 'Effective Date Descending', column: 'effective_date', direction: 'desc', order: 'effective_date DESC' },
    ]
  end
  helper_method :sort_options

  def sort_string
    @column = params[:sort] || 'name'
    @direction = params[:direction] || 'asc'

    result = sort_options.select do |m|
      m[:column] == @column && m[:direction] == @direction
    end.first[:order]

    result += ' NULLS LAST' if ActiveRecord::Base.connection.adapter_name.in?(['PostgreSQL', 'PostGIS'])
    result
  end
end

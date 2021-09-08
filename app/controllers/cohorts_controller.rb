###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CohortsController < ApplicationController
  include AjaxModalRails::Controller
  include CohortAuthorization
  include CohortClients
  before_action :some_cohort_access!
  before_action :require_can_manage_cohorts!, only: [:create, :destroy]
  before_action :require_can_manage_some_cohorts!, only: [:edit, :update]
  before_action :require_can_access_cohort!, only: [:show]
  before_action :set_cohort, only: [:edit, :update, :destroy, :show]
  before_action :set_groups, only: [:edit, :update, :destroy, :show]
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
    @search = scope.ransack(params[:q])

    @cohort = cohort_source.new
    @cohorts = @search.result.active_user.reorder(sort_string)
    @inactive_cohorts = @search.result.inactive.reorder(sort_string)
    @system_cohorts = if ::GrdaWarehouse::Config.get(:enable_system_cohorts)
      @search.result.system_cohorts.reorder(sort_string)
    else
      scope.none
    end
  end

  def show
    @modal_size = :xl
    params[:population] ||= :active
    load_cohort_names
    @cohort = cohort_scope.find(cohort_id)
    # leave off the pagination here and return all the data
    @cohort_clients = @cohort.search_clients(population: params[:population], user: current_user)
    # redirect_to cohorts_path(population: ) if @cohort.needs_client_search?
    @cohort_client_updates = @cohort.cohort_clients.select(:id, :updated_at).map { |m| [m.id, m.updated_at.to_i] }.to_h
    @population = params[:population]
    respond_to do |format|
      format.html do
        @visible_columns = [CohortColumns::Meta.new]
        @visible_columns += @cohort.visible_columns(user: current_user)
        @visible_columns << CohortColumns::Delete.new if (can_manage_cohorts? || can_edit_cohort_clients?) && ! @cohort.system_cohort
        @column_headers = @visible_columns.each_with_index.map do |col, index|
          header = {
            headerName: col.title,
            field: col.column,
            editable: col.column_editable? && col.editable,
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
      end
      format.xlsx do
        @user = current_user
        not_authorized! unless can_download_cohorts?

        headers['Content-Disposition'] = "attachment; filename=#{@cohort.sanitized_name}.xlsx"
      end
    end
  end

  def edit
  end

  def destroy
    @cohort.destroy unless @cohort.system_cohort
    redirect_to cohorts_path
  end

  def create
    @cohort = cohort_source.create!(cohort_params)
    respond_with(@cohort, location: cohort_path(@cohort))
  rescue Exception => e
    flash[:error] = e.message
    redirect_to cohorts_path
  end

  def update
    cohort_options = cohort_params.except(:user_ids)
    cohort_options = cohort_options.except(:name) if @cohort.system_cohort
    user_ids = cohort_params[:user_ids].select(&:present?).map(&:to_i)
    @cohort.update(cohort_options)
    @cohort.update_access(user_ids)
    respond_with(@cohort, location: cohort_path(@cohort))
  end

  def cohort_params
    opts = [
      :name,
      :short_name,
      :effective_date,
      :visible_state,
      :days_of_inactivity,
      :default_sort_direction,
      :only_window,
      :active_cohort,
      :static_column_count,
      :show_on_client_dashboard,
      :visible_in_cas,
      :assessment_trigger,
      :tag_id,
      user_ids: [],
    ] + GrdaWarehouse::Cohort.threshold_keys
    params.require(:grda_warehouse_cohort).permit(opts)
  end

  def set_assessment_types
    @assessment_types ||= begin # rubocop:disable  Naming/MemoizedInstanceVariableName
      types = []
      if can_view_vspdat?
        types += [
          ['Youth VI-SPDAT', GrdaWarehouse::Vispdat::Youth],
          ['Individual VI-SPDAT', GrdaWarehouse::Vispdat::Individual],
          ['Family VI-SPDAT', GrdaWarehouse::Vispdat::Family],
        ]
      end
      types << ['Individual CE Assessment', GrdaWarehouse::CoordinatedEntryAssessment::Individual] if can_view_ce_assessment?

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
    @cohort_names ||= cohort_source.pluck(:id, :name, :short_name).  # rubocop:disable  Naming/MemoizedInstanceVariableName
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
      { title: 'Effective Date Decending', column: 'effective_date', direction: 'desc', order: 'effective_date DESC' },
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

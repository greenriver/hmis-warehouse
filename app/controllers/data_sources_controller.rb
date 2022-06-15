###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DataSourcesController < ApplicationController
  before_action :require_can_edit_projects!, only: [:update]
  before_action :require_can_edit_data_sources!, only: [:new, :create, :destroy, :edit, :update]
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show, :index]
  before_action :set_data_source, only: [:show, :edit, :update, :destroy]

  def index
    # search
    @data_sources = if params[:q].present?
      data_source_scope.text_search(params[:q])
    else
      data_source_scope
    end
    @pagy, @data_sources = pagy(@data_sources.order(name: :asc))
    # @data_spans_by_id = GrdaWarehouse::DataSource.data_spans_by_id
    @client_counts = @data_sources.map { |ds| [ds.id, ds.client_count] }.to_h
    @project_counts = @data_sources.map { |ds| [ds.id, ds.project_count] }.to_h
  end

  def show
    @readonly = ! (can_edit_data_sources? || can_edit_projects?)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    o_t = GrdaWarehouse::Hud::Organization.arel_table
    @organizations = @data_source.organizations.
      joins(:projects).
      merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
      order(o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.new(new_data_source_params)
    @data_source.source_type = :authoritative if new_data_source_params[:authoritative]
    if @data_source.save
      current_user.add_viewable @data_source
      flash[:notice] = "#{@data_source.name} created."
      redirect_to action: :index
    else
      flash[:error] = _('Unable to create new Data Source')
      render action: :new
    end
  end

  def edit
  end

  def update
    error = false
    begin
      GrdaWarehouse::Hud::Project.transaction do
        name = data_source_params[:name]
        short_name = data_source_params[:short_name]
        visible_in_window = data_source_params[:visible_in_window] || false
        import_paused = data_source_params[:import_paused] || false
        source_id = data_source_params[:source_id]
        munged_personal_id = data_source_params[:munged_personal_id] || false
        service_scannable = data_source_params[:service_scannable] || false
        authoritative = data_source_params[:authoritative] || false
        authoritative_type = data_source_params[:authoritative_type]
        after_create_path = data_source_params[:after_create_path]
        changes = {
          name: name,
          short_name: short_name,
          visible_in_window: visible_in_window,
          import_paused: import_paused,
          munged_personal_id: munged_personal_id,
          service_scannable: service_scannable,
          source_id: source_id,
          authoritative: authoritative,
          authoritative_type: authoritative_type,
          after_create_path: after_create_path,
        }
        @data_source.update!(changes)
      end
    rescue StandardError => e
      error = true
    end
    if error
      flash[:error] = "Unable to update data source. #{e}"
      render :show
    else
      redirect_to data_source_path(@data_source), notice: 'Data Source updated'
    end
  end

  def destroy
    name = @data_source.name
    @data_source.destroy_dependents!
    @data_source.destroy
    flash[:notice] = "Data Source: #{name} was successfully removed."

    redirect_to action: :index
  end

  private def data_source_params
    params.require(:grda_warehouse_data_source).
      permit(
        :name,
        :short_name,
        :authoritative,
        :authoritative_type,
        :after_create_path,
        :visible_in_window,
        :import_paused,
        :source_id,
        :munged_personal_id,
        :service_scannable,
        projects_attributes:
        [
          :id,
          :act_as_project_type,
          :hud_coc_code,
          :hud_continuum_funded,
          :housing_type_override,
          :uses_move_in_date,
          :geocode_override,
          :geography_type_override,
          :zip_override,
          :confidential,
          :after_create_path,
        ],
      )
  end

  private def new_data_source_params
    params.require(:grda_warehouse_data_source).
      permit(
        :name,
        :short_name,
        :munged_personal_id,
        :source_type,
        :visible_in_window,
        :authoritative,
        :authoritative_type,
        :after_create_path,
        :import_paused,
        :source_id,
        :service_scannable,
      )
  end

  private def data_source_source
    GrdaWarehouse::DataSource.viewable_by current_user
  end

  private def data_source_scope
    data_source_source.source
  end

  private def set_data_source
    @data_source = data_source_source.find(params[:id].to_i)
  end
end

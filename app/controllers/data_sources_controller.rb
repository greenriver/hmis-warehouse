###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      eager_load(:projects).
      merge(
        GrdaWarehouse::Hud::Project.viewable_by(
          current_user,
          confidential_scope_limiter: :all,
          permission: :can_view_projects,
        ),
      ).
      order(o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.new(new_data_source_params)
    @data_source.source_type = :authoritative if new_data_source_params[:authoritative]
    if @data_source.save
      @data_source.replace_access([current_user], scope: :editor)
      current_user.add_viewable(@data_source) # TODO: START_ACL remove when ACL transition complete
      flash[:notice] = "#{@data_source.name} created."
      redirect_to action: :index
    else
      flash[:error] = Translation.translate('Unable to create new Data Source')
      render action: :new
    end
  end

  def edit
  end

  def update
    error = false
    begin
      @data_source.update!(data_source_params)
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
    DeleteItemJob.perform_later(item_id: @data_source.id, item_class: @data_source.class.name)
    flash[:notice] = "Data Source: #{name} was successfully queued for removal.  Please check back in a few minutes."

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
        :obey_consent,
        projects_attributes:
        [
          :id,
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
        :obey_consent,
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

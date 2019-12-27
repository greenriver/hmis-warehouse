###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class AdHocDataSourcesController < ApplicationController
  before_action :can_manage_ad_hoc_data_sources!
  before_action :set_data_source, only: [:show, :update, :destroy]

  def index
    @data_sources = data_source_scope.order(name: :asc).page(params[:page]).per(25)
  end

  def show
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.new(data_source_params)
    if @data_source.save
      current_user.add_viewable @data_source
      flash[:notice] = "#{@data_source.name} created."
      redirect_to action: :index
    else
      flash[:error] = _('Unable to create new Data Source')
      render action: :new
    end
  end

  def update
    error = false
    begin
      GrdaWarehouse::Hud::Project.transaction do
        visible_in_window = data_source_params[:visible_in_window] || false
        import_paused = data_source_params[:import_paused] || false
        source_id = data_source_params[:source_id]
        @data_source.update!(visible_in_window: visible_in_window, import_paused: import_paused, source_id: source_id)
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
    ds_name = @data_source.name
    if @data_source.has_data?
      flash[:error] = "Unable to delete #{ds_name}, there is data associated with it."
    else
      @data_source.destroy
      flash[:notice] = "Data Source: #{ds_name} was successfully removed."
    end
    redirect_to action: :index
  end

  private def data_source_params
    params.require(:grda_warehouse_data_source).
      permit(
        :name,
        :short_name,
        :description,
        :active,
      )
  end

  private def data_source_source
    GrdaWarehouse::AdHocDataSource
  end

  private def data_source_scope
    data_source_source.viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:id].to_i)
  end
end

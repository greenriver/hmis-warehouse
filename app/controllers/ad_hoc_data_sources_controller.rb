###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AdHocDataSourcesController < ApplicationController
  before_action :require_can_manage_some_ad_hoc_ds!
  before_action :set_data_source, only: [:show, :update, :edit, :destroy]

  def index
    @data_sources = data_source_scope.active.order(name: :asc).page(params[:page]).per(25)
  end

  def show
    @uploads = @data_source.ad_hoc_batches.order(id: :desc).page(params[:page]).per(25)
  end

  def download
    respond_to do |format|
      format.xlsx do
        headers['Content-Disposition'] = 'attachment; filename=ad-hoc-template.xlsx'
      end
    end
  end

  def edit
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.create(data_source_params.merge(user_id: current_user.id))
    respond_with(@data_source, location: ad_hoc_data_sources_path)
  end

  def update
    opts = data_source_params
    # Because user_id was added at a later date, upgrade any that were unable to be upgrade initially
    opts[:user_id] = current_user.id if @data_source.id.blank?
    @data_source.update!(opts)
    respond_with(@data_source, location: ad_hoc_data_source_path(@data_source))
  end

  def destroy
    @data_source.destroy
    respond_with(@data_source, location: ad_hoc_data_sources_path)
  end

  private def data_source_params
    params.require(:grda_warehouse_ad_hoc_data_source).
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

  def flash_interpolation_options
    { resource_name: 'Ad-Hoc Data Source' }
  end
end

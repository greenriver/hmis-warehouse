###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class AdHocDataSourcesController < ApplicationController
  before_action :require_can_manage_ad_hoc_data_sources!
  before_action :set_data_source, only: [:show, :update, :edit, :destroy]

  def index
    @data_sources = data_source_scope.active.order(name: :asc).page(params[:page]).per(25)
  end

  def show
    @uploads = @data_source.ad_hoc_batches.order(id: :desc).page(params[:page]).per(25)
  end

  def download
    send_data data_source_source.blank_csv, filename: 'ad-hoc-template.csv'
  end

  def edit
  end

  def new
    @data_source = data_source_source.new
  end

  def create
    @data_source = data_source_source.create(data_source_params)
    respond_with(@data_source, location: ad_hoc_data_sources_path)
  end

  def update
    @data_source.update!(data_source_params)
    respond_with(@data_source, location: ad_hoc_data_source_path(@data_source))
  end

  def destroy
    @data_source.destroy
    respond_with(@data_source)
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

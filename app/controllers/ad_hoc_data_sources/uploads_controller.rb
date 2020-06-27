###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AdHocDataSources::UploadsController < ApplicationController
  before_action :require_can_manage_ad_hoc_data_sources!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :destroy, :download]

  def index
    attributes = upload_source.column_names - ['content', 'file']
    @uploads = @data_source.ad_hoc_batches.select(*attributes).
      page(params[:page].to_i).per(20).order(created_at: :desc)
  end

  def new
    @upload = upload_source.new
  end

  def show
  end

  def download
    send_data @upload.content, filename: @upload.name
  end

  def destroy
    @upload.destroy
    respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
  end

  def create
    # NOTE: sometimes Excel likes to add BOMs.  We don't need those, and anything else that's in upper ASCII can go too
    clean_file = upload_params[:file]&.read&.gsub(/[^[:ascii:]]/, '')
    @upload = upload_source.create(upload_params.merge(ad_hoc_data_source_id: @data_source.id, content: clean_file, user_id: current_user&.id))
    respond_with(@upload, location: ad_hoc_data_source_path(@data_source))
  end

  private def upload_params
    params.require(:grda_warehouse_ad_hoc_batch).
      permit(:file, :description)
  end

  private def data_source_source
    GrdaWarehouse::AdHocDataSource
  end

  private def data_source_scope
    data_source_source.viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:ad_hoc_data_source_id].to_i)
  end

  private def set_upload
    @upload = upload_source.find(params[:id].to_i)
  end

  def upload_source
    GrdaWarehouse::AdHocBatch
  end

  def flash_interpolation_options
    { resource_name: 'Ad-Hoc Upload' }
  end
end

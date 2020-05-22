###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisImportConfigsController < ApplicationController
  before_action :require_can_edit_data_sources_or_everything!
  before_action :set_data_source
  before_action :set_config, only: [:edit, :update, :destroy]

  def new
    redirect_to action: :edit if config_exists?
    @config = config_scope.new
  end

  def edit
  end

  def update
    @config.update(config_params)
    respond_with(@config, location: edit_data_source_hmis_import_config_path)
  end

  def create
    @config = config_scope.create(config_params)
    respond_with(@config, location: edit_data_source_hmis_import_config_path)
  end

  private def config_exists?
    GrdaWarehouse::HmisImportConfig.where(data_source_id: params[:data_source_id].to_i).exists?
  end

  private def set_data_source
    @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id].to_i)
  end

  private def set_config
    @config = config_scope.find_by(data_source_id: params[:data_source_id].to_i)
  end

  private def config_scope
    GrdaWarehouse::HmisImportConfig.where(data_source_id: @data_source.id)
  end

  private def config_params
    params.require(:config).permit(
      :active,
      :s3_access_key_id,
      :s3_secret_access_key,
      :s3_region,
      :s3_bucket_name,
      :s3_path,
      :zip_file_password,
    )
  end

  def flash_interpolation_options
    { resource_name: 'HMIS CSV Config' }
  end
end

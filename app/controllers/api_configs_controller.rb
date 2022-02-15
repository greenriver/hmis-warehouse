###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApiConfigsController < ApplicationController
  before_action :require_can_edit_data_sources!
  before_action :require_can_manage_config!
  before_action :set_data_source
  before_action :set_config, only: [:edit, :update, :create, :destroy]

  def new
    redirect_to action: :edit if config_exists?
    @config = config_scope.new
  end

  def edit
  end

  def update
    cleaned_params = handle_json_fields(config_params)
    @config.update(cleaned_params)
    respond_with(@config, location: edit_data_source_api_config_path)
  end

  def create
    cleaned_params = handle_json_fields(config_params)
    @config = config_scope.create(cleaned_params)
    respond_with(@config, location: edit_data_source_api_config_path)
  end

  private def config_exists?
    GrdaWarehouse::EtoApiConfig.where(data_source_id: params[:data_source_id].to_i).exists?
  end

  private def set_data_source
    @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id].to_i)
  end

  private def set_config
    @config = config_scope.find_by(data_source_id: params[:data_source_id].to_i)
  end

  private def config_scope
    GrdaWarehouse::EtoApiConfig.where(data_source_id: @data_source.id)
  end

  private def config_params
    params.require(:config).permit(
      :active,
      :touchpoint_fields,
      :demographic_fields,
      :demographic_fields_with_attributes,
      :additional_fields,
      :identifier,
      :email,
      :password,
      :enterprise,
      :hud_touch_point_id,
    )
  end

  private def handle_json_fields(config)
    [
      :touchpoint_fields,
      :demographic_fields,
      :demographic_fields_with_attributes,
      :additional_fields,
    ].each do |field|
      config[field] = JSON.parse(config[field])
    rescue JSON::ParserError
      config[field] = "FAILED to parse: #{config[field]}"
    end
    config
  end

  def flash_interpolation_options
    { resource_name: 'ETO Configuration' }
  end
end

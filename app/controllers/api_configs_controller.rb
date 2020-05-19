###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ApiConfigsController < ApplicationController
  before_action :require_can_edit_data_sources_or_everything!
  before_action :set_data_source
  before_action :set_config, only: [:edit, :update, :create, :destroy]

  def new
    redirect_to action: :edit if config_exists?
    @config = config_scope.new
  end

  def edit
  end

  def update
    respond_with @config.update(config_params)
  end

  def create
    respond_with config_scope.create(config_params)
  end

  def destroy
  end

  private def config_exists?
    GrdaWarehouse::EtoApiConfig.where(data_source_id: params[:data_source_id].to_i).exists?
  end

  private def set_data_source
    @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id].to_i)
  end

  private def set_config
    @config = config_scope.find(params[:id].to_i)
  end

  private def config_scope
    GrdaWarehouse::EtoApiConfig.where(data_source_id: @data_source.id)
  end

  private def config_params
    require(:config).permit(
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
end

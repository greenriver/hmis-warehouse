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
  end

  def edit
  end

  def update
  end

  def create
  end

  def destroy
  end

  private def set_data_source
    @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(parms[:data_source_id].to_i)
  end

  private def set_config
    @config = GrdaWarehouse::EtoApiConfig.where(data_source_id: @data_source.id).find(params[:id].to_i)
  end
end

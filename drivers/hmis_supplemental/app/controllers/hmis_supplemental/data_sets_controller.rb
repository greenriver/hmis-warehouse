###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Manage data sets
module HmisSupplemental
  class DataSetsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :require_can_edit_data_sources!
    before_action :load_authorized_data_source

    def index
      @data_sets = data_set_scope
    end

    def new
      @data_set = data_set_scope.new(field_config: '[]')
      @data_set.build_remote_credential
    end

    def create
      @data_set = data_set_scope.new(data_set_params)
      cred = @data_set.build_remote_credential
      cred.active = true
      @data_set.attributes = data_set_params
      if @data_set.save
        flash[:notice] = 'Data set created'
        redirect_to action: :index
      else
        render :new
      end
    end

    def edit
      @data_set = load_data_set
    end

    def update
      @data_set = load_data_set
      @data_set.attributes = data_set_params
      if @data_set.save
        flash[:notice] = "#{@data_set.name} was successfully updated."
        redirect_to action: :index
      else
        render :edit
      end
    end

    def destroy
      @data_set = load_data_set
      @data_set.destroy!
      flash[:notice] = 'data set was removed'
      redirect_to action: :index
    end

    protected

    def load_authorized_data_source
      @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id])
    end

    def load_data_set
      data_set_scope.find(params[:id])
    end

    def data_set_scope
      HmisSupplemental::DataSet.where(data_source: @data_source).order(:id)
    end

    def data_set_params
      params.require(:data_set).permit(
        :name,
        :object_key,
        :owner_type,
        :field_config,
        remote_credential_attributes: [
          :region,
          :bucket,
          :s3_access_key_id,
          :s3_secret_access_key,
          :s3_prefix,
        ],
      )
    end
  end
end

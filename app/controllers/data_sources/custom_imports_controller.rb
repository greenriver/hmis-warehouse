###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DataSources
  class CustomImportsController < ApplicationController
    before_action :require_can_edit_data_sources!
    before_action :require_can_manage_config!
    before_action :set_data_source
    before_action :set_config, only: [:show, :edit, :update, :destroy]

    def index
      @configs = config_scope
    end

    def show
      @files = @config.import_type.constantize.where(config_id: @config.id).
        order(created_at: :desc).
        page(params[:page]).per(25)
    end

    def new
      @config = config_source.new(import_hour: 4)
    end

    def edit
      @bucket_objects_list = []
      @error = false
      begin
        @bucket_objects_list = @config.s3.list_objects(25, prefix: @config.s3_prefix)
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::AccessDenied, Aws::S3::Errors::SignatureDoesNotMatch
        @error = true
      end
    end

    def create
      @config = config_source.create(config_params.merge(user_id: current_user.id, data_source_id: @data_source.id))
      respond_with(@config, location: data_source_custom_imports_path(@data_source))
    end

    def update
      @config = config_source.update(config_params.merge(user_id: current_user.id, data_source_id: @data_source.id))
      respond_with(@config, location: data_source_custom_imports_path(@data_source))
    end

    def destroy
      @config.destroy
      respond_with(@config, location: data_source_custom_imports_path(@data_source))
    end

    private def config_params
      params.require(:config).permit(
        :import_type,
        :description,
        :import_hour,
        :s3_access_key_id,
        :s3_secret_access_key,
        :s3_region,
        :s3_bucket,
        :s3_prefix,
      )
    end

    private def config_scope
      config_source.for_data_source(@data_source).active
    end

    private def config_source
      GrdaWarehouse::CustomImports::Config
    end

    private def set_data_source
      @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id].to_i)
    end

    private def set_config
      @config = config_scope.find(params[:id].to_i)
    end

    def flash_interpolation_options
      { resource_name: 'Custom Import Configuration' }
    end
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class PublicConfigsController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @config = config_source.first_or_create
    end

    def create
      @config = config_source.first_or_create
      @config.update(config_params)
      respond_with(@config, location: public_reports_warehouse_reports_public_configs_path)
    end

    def config_params
      params.require(:config).permit(
        :s3_region,
        :s3_bucket,
        :s3_prefix,
        :s3_access_key_id,
        :s3_secret,
        :color_0,
        :color_1,
        :color_2,
        :color_3,
        :color_4,
        :color_5,
        :color_6,
        :color_7,
        :color_8,
        :color_9,
        :color_10,
        :color_11,
        :color_12,
        :color_13,
        :color_14,
        :color_15,
        :color_16,
        :font_url,
        :font_family_0,
        :font_family_1,
        :font_family_2,
        :font_family_3,
        :font_size_0,
        :font_size_1,
        :font_size_2,
        :font_size_3,
        :font_weight_0,
        :font_weight_1,
        :font_weight_2,
        :font_weight_3,
      )
    end

    private def config_source
      PublicReports::Setting
    end

    private def flash_interpolation_options
      { resource_name: 'Public Report Config' }
    end
  end
end

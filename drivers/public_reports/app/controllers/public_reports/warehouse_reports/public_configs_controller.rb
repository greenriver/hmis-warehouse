###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        :map_type,
        :summary_color,
        :homeless_primary_color,
        :youth_primary_color,
        :adults_only_primary_color,
        :adults_with_children_primary_color,
        :children_only_primary_color,
        :veterans_primary_color,
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
        :gender_color_0,
        :gender_color_1,
        :gender_color_2,
        :gender_color_3,
        :gender_color_4,
        :gender_color_5,
        :gender_color_6,
        :gender_color_7,
        :gender_color_8,
        :age_color_0,
        :age_color_1,
        :age_color_2,
        :age_color_3,
        :age_color_4,
        :age_color_5,
        :age_color_6,
        :age_color_7,
        :age_color_8,
        :household_composition_color_0,
        :household_composition_color_1,
        :household_composition_color_2,
        :household_composition_color_3,
        :household_composition_color_4,
        :household_composition_color_5,
        :household_composition_color_6,
        :household_composition_color_7,
        :household_composition_color_8,
        :race_color_0,
        :race_color_1,
        :race_color_2,
        :race_color_3,
        :race_color_4,
        :race_color_5,
        :race_color_6,
        :race_color_7,
        :race_color_8,
        :time_color_0,
        :time_color_1,
        :time_color_2,
        :time_color_3,
        :time_color_4,
        :time_color_5,
        :time_color_6,
        :time_color_7,
        :time_color_8,
        :housing_type_color_0,
        :housing_type_color_1,
        :housing_type_color_2,
        :housing_type_color_3,
        :housing_type_color_4,
        :housing_type_color_5,
        :housing_type_color_6,
        :housing_type_color_7,
        :housing_type_color_8,
        :population_color_0,
        :population_color_1,
        :population_color_2,
        :population_color_3,
        :population_color_4,
        :population_color_5,
        :population_color_6,
        :population_color_7,
        :population_color_8,
        :location_type_color_0,
        :location_type_color_1,
        :location_type_color_2,
        :location_type_color_3,
        :location_type_color_4,
        :location_type_color_5,
        :location_type_color_6,
        :location_type_color_7,
        :location_type_color_8,
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

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class CensusReportFilter < HudFilterBase
    attribute :aggregation_level, String, default: :by_project
    attribute :aggregation_type, String, default: :inventory
    attribute :limit_es_to_nbn, Boolean, default: false

    validates_presence_of :start, :end

    def update(filters)
      super
      self.aggregation_level = filters.dig(:aggregation_level)&.to_sym || aggregation_level
      self.aggregation_type = filters.dig(:aggregation_type)&.to_sym || aggregation_type
      self.limit_es_to_nbn = filters.dig(:limit_es_to_nbn).in?(['1', 'true', true]) unless filters.dig(:limit_es_to_nbn).nil?
      self
    end
    alias set_from_params update

    def known_params
      super << [
        :aggregation_level,
        :aggregation_type,
        :limit_es_to_nbn,
      ]
    end

    def for_params
      {
        filters: {
          **super[:filters],
          aggregation_level: aggregation_level.titleize,
          aggregation_type: aggregation_type.titleize,
          limit_es_to_nbn: limit_es_to_nbn,
        },
      }
    end

    def params_for_display
      [
        :start,
        :end,
        :coc_codes,
        :project_type_codes,
        :project_ids,
        :organization_ids,
        :project_group_ids,
        :data_source_ids,
        :aggregation_level,
        :aggregation_type,
        :limit_es_to_nbn,
      ]
    end

    def project_type_code_options_for_select
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.freeze.invert
    end

    # These are not presented in the UI, but need to be set to nothing or all homeless projects are returned
    def default_project_type_codes
      []
    end
  end
end

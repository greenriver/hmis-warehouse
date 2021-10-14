###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Filters
  class PathFilter < ::Filters::HudFilterBase
    def default_project_type_codes
      [:so, :services_only]
    end

    def project_options_for_select(user:)
      path_funded = ::GrdaWarehouse::Hud::Funder.funding_source(funder_code: 21)
      all_project_scope.joins(:funders).options_for_select(user: user, scope: path_funded)
    end

    def path_project_types_for_select
      GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.select { |k, _| k.in?([:so, :services_only]) }.invert.freeze
    end
  end
end

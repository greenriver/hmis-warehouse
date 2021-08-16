###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Filters
  class DqFilter < ::Filters::HudFilterBase
    def default_project_type_codes
      []
    end
  end
end

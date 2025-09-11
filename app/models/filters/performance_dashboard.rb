###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class PerformanceDashboard < FilterBase
    def default_project_type_codes
      HudUtilityCurrent.homeless_project_type_codes
    end
  end
end

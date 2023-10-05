###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class PerformanceDashboard < FilterBase
    def default_project_type_codes
      HudUtility2024.homeless_project_type_codes
    end
  end
end

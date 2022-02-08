###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class PerformanceDashboard < FilterBase
    def default_project_type_codes
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES
    end
  end
end

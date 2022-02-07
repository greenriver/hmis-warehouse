###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class DateRangeAndSourcesResidentialOnly < DateRangeAndSources
    def all_project_scope
      GrdaWarehouse::Hud::Project.residential.viewable_by(user)
    end
  end
end

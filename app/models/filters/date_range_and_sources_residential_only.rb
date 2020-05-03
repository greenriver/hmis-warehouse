###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Filters
  class DateRangeAndSourcesResidentialOnly < DateRangeAndSources

    def all_project_scope
      GrdaWarehouse::Hud::Project.residential.viewable_by(user)
    end
  end
end
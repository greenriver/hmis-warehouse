###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class DateRangeAndSourcesResidentialOnly < FilterBase
    def all_project_scope
      GrdaWarehouse::Hud::Project.residential.viewable_by(user)
    end
  end
end

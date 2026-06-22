###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class PerformanceDashboardByProjectType < FilterBase
    def default_project_type_codes
      [:es]
    end
  end
end

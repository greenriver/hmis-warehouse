###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class DateRangeAndProject < DateRange
    attribute :project_type, Array[String]

    def project_types
      GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.map(&:reverse)
    end
  end
end

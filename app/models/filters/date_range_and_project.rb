###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class DateRangeAndProject < DateRange
    attribute :project_type, Array[String]

    def project_types
      HudUtility2024.homeless_type_titles.map(&:reverse)
    end
  end
end

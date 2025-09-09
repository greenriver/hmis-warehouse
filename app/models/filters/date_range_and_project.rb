###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class DateRangeAndProject < DateRange
    attribute :project_type, Array[String]

    def project_types
      HudUtility2026.homeless_type_titles.map(&:reverse)
    end
  end
end

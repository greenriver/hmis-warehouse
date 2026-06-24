###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class DateRangeAndProject < DateRange
    attribute :project_type, Array[String]

    def project_types
      HudHelper.util.homeless_type_titles.map(&:reverse)
    end
  end
end

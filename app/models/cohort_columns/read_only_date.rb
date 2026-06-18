###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class ReadOnlyDate < ReadOnly
    def date_format
      'll'
    end

    def renderer
      'date'
    end
  end
end

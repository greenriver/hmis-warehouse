###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ExitDestination < Select
    attribute :column, String, lazy: true, default: :exit_destination
    attribute :translation_key, String, lazy: true, default: 'Exit Destination'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Manually entered destination'
    end
  end
end

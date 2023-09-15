###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class SleepingLocation < Select
    attribute :column, String, lazy: true, default: :sleeping_location
    attribute :translation_key, String, lazy: true, default: 'Sleeping Location'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }

    def description
      'Manually entered'
    end
  end
end

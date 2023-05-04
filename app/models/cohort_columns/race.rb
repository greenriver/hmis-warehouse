###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Race < ReadOnly
    attribute :column, String, lazy: true, default: :race
    attribute :translation_key, String, lazy: true, default: 'Race'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client)
      cohort_client.client.race_fields&.sort
    end

    def display_read_only(_user)
      races = value(cohort_client)
      return '' unless races

      races.map do |k|
        ::HudUtility.races[k]
      end.join('; ')
    end
  end
end

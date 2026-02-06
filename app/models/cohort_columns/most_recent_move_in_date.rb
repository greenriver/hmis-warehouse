###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class MostRecentMoveInDate < ReadOnlyDate
    attribute :column, String, lazy: true, default: :most_recent_move_in_date
    attribute :translation_key, String, lazy: true, default: 'Most-Recent Move-In Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Most recent move-in date for ongoing PH enrollments.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val&.to_date
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.most_recent_move_in_date&.to_s
    end
  end
end

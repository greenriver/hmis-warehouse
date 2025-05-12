###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class MostRecentDateToStreet < ReadOnly
    attribute :column, String, lazy: true, default: :most_recent_date_to_street
    attribute :translation_key, String, lazy: true, default: 'Most Recent Date To Street'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'The most-recent response to 3.917.3 Approximate date this episode of homelessness started on a homeless enrollment based on EntryDate and DateUpdated.  If this cohort uses automation, the situation will be limited to projects in the selected project group.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_date
    end

    def value(cohort_client) # OK
      date = cohort_client.most_recent_date_to_street&.to_date
      return unless date.present?

      days = (Date.current - date).to_i
      "#{date} (#{days} days)"
    end

    def analytics_data_type
      'date'
    end
  end
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class MostRecentDateToStreet < ReadOnly
    attribute :column, String, lazy: true, default: :most_recent_date_to_street
    attribute :translation_key, String, lazy: true, default: 'Most Recent Date To Street'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def cast_value(val)
      val.to_date
    end

    def value(cohort_client) # OK
      date = cohort_client.most_recent_date_to_street&.to_date
      return unless date.present?

      days = (Date.current - date).to_i
      "#{date&.to_s} (#{days} days)"
    end
  end
end

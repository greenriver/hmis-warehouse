###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DateAddedToCohort < ReadOnly
    attribute :column, String, lazy: true, default: :date_added_to_cohort
    attribute :translation_key, String, lazy: true, default: 'Date Added to Cohort'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'The most-recent date that a client was added to the cohort.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_date
    end

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      cohort_client.date_added_to_cohort&.to_date&.to_s
    end

    def default_value?
      true
    end

    def default_value(_client_id)
      Date.current
    end
  end
end

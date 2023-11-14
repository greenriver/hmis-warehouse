###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DisabilityVerificationDate < ReadOnly
    attribute :column, String, lazy: true, default: :disability_verification_date
    attribute :translation_key, String, lazy: true, default: 'Disability Verification Upload Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_date
    end

    def date_format
      'll'
    end

    def value(cohort_client) # OK
      cohort_client.disability_verification_date&.to_s
    end
  end
end

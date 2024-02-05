###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class RrhDesired < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_desired
    attribute :translation_key, String, lazy: true, default: 'Interested in RRH'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'True if the client indicated an interest in RRH for CAS'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_s == 'true'
    end

    def arel_col
      c_t[:rrh_desired]
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value(cohort_client)
      cohort_client.client.rrh_desired
    end
  end
end

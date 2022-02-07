###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class RrhAssessmentContactInfo < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_assessment_contact_info
    attribute :translation_key, String, lazy: true, default: 'RRH Income Maximization Contact'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      # FIXME?: contact_info_for_rrh_assessment already checks consent_form_valid?
      cohort_client.client.contact_info_for_rrh_assessment if cohort_client.client.consent_form_valid?
    end

    def text_value(cohort_client)
      strip_tags value(cohort_client)
    end
  end
end

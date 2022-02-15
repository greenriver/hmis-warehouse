###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ConsentConfirmed < ReadOnly
    attribute :column, String, lazy: true, default: :consent_confirmed
    attribute :translation_key, String, lazy: true, default: 'Consent Confirmed'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def renderer
      'html'
    end

    def value(cohort_client)
      html = checkmark_or_x text_value(cohort_client)
      html += content_tag(:span, cohort_client.client.release_current_status, class: 'mp-2')
      html
    end

    def text_value(cohort_client)
      cohort_client.client.consent_confirmed?
    end
  end
end

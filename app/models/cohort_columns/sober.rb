module CohortColumns
  class Sober < ReadOnly
    attribute :column, String, lazy: true, default: :sober
    attribute :translation_key, String, lazy: true, default: 'Appropriate for Sober Supportive Housing'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.sober_housing
    end
  end
end

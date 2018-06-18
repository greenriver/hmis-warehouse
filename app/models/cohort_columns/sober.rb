module CohortColumns
  class Sober < ReadOnly
    attribute :column, String, lazy: true, default: :sober
    attribute :title, String, lazy: true, default: 'Appropriate for Sober Supportive Housing'

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

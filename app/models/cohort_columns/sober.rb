module CohortColumns
  class Sober < ReadOnly
    attribute :column, String, lazy: true, default: :sober
    attribute :title, String, lazy: true, default: 'Appropriate for Sober Supportive Housing'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x cohort_client.client.sober_housing
    end
  end
end

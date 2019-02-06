module CohortColumns
  class FirstDateHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :translation_key, String, lazy: true, default: 'First Date Homeless'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      cohort_client.client.first_homeless_date&.to_date&.to_s
    end

  end
end

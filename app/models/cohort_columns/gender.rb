module CohortColumns
  class Gender < ReadOnly
    attribute :column, String, lazy: true, default: :gender
    attribute :translation_key, String, lazy: true, default: 'Gender'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.client.gender
    end
  end
end

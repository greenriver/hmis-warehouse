module CohortColumns
  class Veteran < CohortBoolean
    attribute :column, String, lazy: true, default: :veteran
    attribute :translation_key, String, lazy: true, default: 'Veteran'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.client.veteran?
    end
  end
end

module CohortColumns
  class VaEligible < Select
    attribute :column, String, lazy: true, default: :va_eligible
    attribute :translation_key, String, lazy: true, default: 'VA Eligible'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

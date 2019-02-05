module CohortColumns
  class Reported < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :reported
    attribute :translation_key, String, lazy: true, default: 'Reported'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

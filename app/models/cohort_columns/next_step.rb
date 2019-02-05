module CohortColumns
  class NextStep < CohortString
    attribute :column, String, lazy: true, default: :next_step
    attribute :translation_key, String, lazy: true, default: 'Next Step'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

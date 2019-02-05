module CohortColumns
  class SpecialNeeds < CohortString
    attribute :column, String, lazy: true, default: :special_needs
    attribute :translation_key, String, lazy: true, default: 'Special Needs'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

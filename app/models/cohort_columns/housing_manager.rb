module CohortColumns
  class HousingManager < CohortString
    attribute :column, String, lazy: true, default: :housing_manager
    attribute :translation_key, String, lazy: true, default: 'Housing Manager'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

module CohortColumns
  class HousingNavigator < CohortString
    attribute :column, String, lazy: true, default: :housing_navigator
    attribute :translation_key, String, lazy: true, default: 'Housing Navigator'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

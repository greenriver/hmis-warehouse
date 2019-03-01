module CohortColumns
  class HousingPlan < ::CohortColumns::Text
    attribute :column, String, lazy: true, default: :housing_plan
    attribute :translation_key, String, lazy: true, default: 'Housing Plan'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

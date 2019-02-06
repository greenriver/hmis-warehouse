module CohortColumns
  class UserBoolean3 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_3
    attribute :translation_key, String, lazy: true, default: 'User Boolean 3'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

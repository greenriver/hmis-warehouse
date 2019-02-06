module CohortColumns
  class UserBoolean2 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_2
    attribute :translation_key, String, lazy: true, default: 'User Boolean 2'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

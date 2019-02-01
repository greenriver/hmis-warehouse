module CohortColumns
  class UserBoolean4 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_4
    attribute :translation_key, String, lazy: true, default: 'User Boolean 4'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

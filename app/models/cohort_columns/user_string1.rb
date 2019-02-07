module CohortColumns
  class UserString1 < CohortString
    attribute :column, String, lazy: true, default: :user_string_1
    attribute :translation_key, String, lazy: true, default: 'User String 1'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

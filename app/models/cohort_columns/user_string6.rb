module CohortColumns
  class UserString6 < CohortString
    attribute :column, String, lazy: true, default: :user_string_6
    attribute :translation_key, String, lazy: true, default: 'User String 6'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

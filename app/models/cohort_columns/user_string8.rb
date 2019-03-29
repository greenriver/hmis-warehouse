module CohortColumns
  class UserString8 < CohortString
    attribute :column, String, lazy: true, default: :user_string_8
    attribute :translation_key, String, lazy: true, default: 'User String 8'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end

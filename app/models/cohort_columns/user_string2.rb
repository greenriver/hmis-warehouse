module CohortColumns
  class UserString2 < CohortString
    attribute :column, String, lazy: true, default: :user_string_2
    attribute :translation_key, String, lazy: true, default: 'User String 2'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end